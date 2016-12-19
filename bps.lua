-- bps.lua
-- Nov 2016

-- Modified by Oarc . Taken from 3Ra with permission.

-- Blueprint String
-- A 3Ra Gaming revision
-- Original Author: DaveMcW

local BlueprintString = require "locale/blueprintstring/blueprintstring"
BlueprintString.COMPRESS_STRINGS = true
BlueprintString.LINE_LENGTH = 120

-- Initialise player GUI
-- @param player
local function init_gui(player)
	if (not player.force.technologies["automated-construction"].researched) then
		return
	end

	if (not player.gui.top["blueprint-string-button"]) then
		player.gui.top.add { type = "button", name = "blueprint-string-button", caption = "BPS" }
	end
end

-- Initialise map
function bps_init()
	for _, player in pairs(game.players) do
		init_gui(player)
	end
end

-- Initialise player
-- @param event on_player_joined event
function bps_player_joined(event)
	init_gui(game.players[event.player_index])
end

-- Handle research completion
-- @param event on_research_finished event
function bps_on_research_finished(event)
	if (event.research.name == "automated-construction") then
		for _, player in pairs(game.players) do
			if (event.research.force.name == player.force.name) then
				init_gui(player)
			end
		end
	end
end

-- Expand player's gui
-- @param player target player
local function expand_gui(player)
	local frame = player.gui.left["blueprint-string"]
	if (frame) then
		frame.destroy()
	else
		frame = player.gui.left.add { type = "frame", name = "blueprint-string" }
		frame.add { type = "label", caption = { "textbox-caption" } }
		frame.add { type = "textfield", name = "blueprint-string-text" }
		frame.add { type = "button", name = "blueprint-string-load", caption = "Load" }
		frame.add { type = "button", name = "blueprint-string-save", caption = "Save" }
		frame.add { type = "button", name = "blueprint-string-save-all", caption = "Save All" }
		frame.add { type = "button", name = "blueprint-string-upgrade", caption = "Upgrade" }
	end
end

-- Trim string of whitespace 
-- @param s string
-- @return trimmed string
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Get the amount of a certain item type in an inventory
-- @param inventory inventory to filter
-- @param type type of item to filter
-- @return array of items
local function filter(inventory, type)
	local stacks = {}
	if (inventory) then
		for i = 1, #inventory do
			if (inventory[i].valid_for_read and inventory[i].type == type) then
				stacks[i] = inventory[i]
			end
		end
	end
	return stacks
end

-- Return the blueprints inside a book
-- @param book blueprint book item
-- @return array of blueprints
local function book_inventory(book)
	local blueprints = {}
	local active = book.get_inventory(defines.inventory.item_active)
	local main = book.get_inventory(defines.inventory.item_main)

	if (active[1].valid_for_read and active[1].type == "blueprint") then
		blueprints[1] = active[1]
	end

	for i = 1, #main do
		if (main[i].valid_for_read and main[i].type == "blueprint") then
			blueprints[i + 1] = main[i]
		end
	end

	return blueprints
end

-- Check if the player is holding a blueprint
-- @param player target player
-- @return bool player is holding blueprint
local function holding_blueprint(player)
	return (player.cursor_stack.valid_for_read and player.cursor_stack.type == "blueprint")
end

-- Check if the blueprint being held is empty
-- @param player target player
-- @return bool blueprint is not empty
local function holding_valid_blueprint(player)
	return (holding_blueprint(player) and player.cursor_stack.is_blueprint_setup())
end

-- Check if the player is holding a blueprint book
-- @param player target player
-- @return bool player is holding book
local function holding_book(player)
	return (player.cursor_stack.valid_for_read and player.cursor_stack.type == "blueprint-book")
end

-- Find a player's empty blueprint or craft one if unavailable
-- @param player target player
-- @param no_crafting if true then a blueprint will not be crafted, even if one is unavailable
-- @return empty blueprint
local function find_empty_blueprint(player, no_crafting)
	if (holding_blueprint(player)) then
		if (player.cursor_stack.is_blueprint_setup()) then
			player.cursor_stack.set_blueprint_entities(nil)
			player.cursor_stack.set_blueprint_tiles(nil)
			player.cursor_stack.label = ""
		end
		return player.cursor_stack
	end

	local main = player.get_inventory(defines.inventory.player_main)
	local quickbar = player.get_inventory(defines.inventory.player_quickbar)

	local stacks = filter(quickbar, "blueprint")
	for i, stack in pairs(filter(main, "blueprint")) do
		stacks[#quickbar + i] = stack
	end
	for _, stack in pairs(stacks) do
		if (not stack.is_blueprint_setup()) then
			return stack
		end
	end

	if (no_crafting) then
		return nil
	end

	-- Craft a new blueprint
	if (player.can_insert("blueprint") and player.get_item_count("advanced-circuit") >= 1) then
		player.remove_item { name = "advanced-circuit", count = 1 }
		if (player.insert("blueprint") == 1) then
			return find_empty_blueprint(player, true)
		end
	end

	return nil
end

-- Find an empty book, or craft one if unavailable
-- @param player target player
-- @param slots number of slots needed
-- @param no_crafting bool to allow crafting or not
-- @return empty blueprint book
local function find_empty_book(player, slots, no_crafting)
	if (holding_book(player)) then
		for _, page in pairs(book_inventory(player.cursor_stack)) do
			if (page.is_blueprint_setup()) then
				page.set_blueprint_entities(nil)
				page.set_blueprint_tiles(nil)
				page.label = ""
			end
		end
		return player.cursor_stack
	end

	local advanced_circuits = player.get_item_count("advanced-circuit")
	local main = player.get_inventory(defines.inventory.player_main)
	local quickbar = player.get_inventory(defines.inventory.player_quickbar)
	local first_empty_book = nil
	local books = filter(quickbar, "blueprint-book")
	for i, book in pairs(filter(main, "blueprint-book")) do
		books[#quickbar + i] = book
	end
	for _, book in pairs(books) do
		local empty = true
		local pages = 0
		for _, page in pairs(book_inventory(book)) do
			if (page.is_blueprint_setup()) then
				empty = false
			end
			pages = pages + 1
		end
		if (empty) then
			if (slots <= pages + advanced_circuits) then
				return book
			end
			if (not first_empty_book) then
				first_empty_book = book
			end
		end
	end

	if (first_empty_book) then
		-- We can't afford to craft all the blueprints, but at least we have an empty book
		return first_empty_book
	end

	if (no_crafting) then
		return nil
	end

	-- Craft a new book
	if (player.can_insert("blueprint-book") and advanced_circuits >= 15 + slots) then
		player.remove_item { name = "advanced-circuit", count = 15 }
		if (player.insert("blueprint-book") == 1) then
			return find_empty_book(player, slots, true)
		end
	end

	return nil
end

-- Convert string into blueprint
-- @param blueprint empty blueprint that the data will be loaded into
-- @param data blueprint data
-- @return error if one occurred
local function load_blueprint_data(blueprint, data)
	if (not data.icons or type(data.icons) ~= "table" or #data.icons < 1) then
		return { "unknown-format" }
	end

	status, result = pcall(blueprint.set_blueprint_entities, data.entities)
	if (not status) then
		blueprint.set_blueprint_entities(nil)
		return { "blueprint-api-error", result }
	end

	status, result = pcall(blueprint.set_blueprint_tiles, data.tiles)
	if (not status) then
		blueprint.set_blueprint_entities(nil)
		blueprint.set_blueprint_tiles(nil)
		return { "blueprint-api-error", result }
	end

	if (blueprint.is_blueprint_setup()) then
		status, result = pcall(function() blueprint.blueprint_icons = data.icons end)
		if (not status) then
			blueprint.set_blueprint_entities(nil)
			blueprint.set_blueprint_tiles(nil)
			return { "blueprint-icon-error", result }
		end
	end

	blueprint.label = data.name or ""

	return nil
end

-- Call the required local functions to load a blueprint
-- @param player player that is loading the blueprint
local function load_blueprint(player)
	local textbox = player.gui.left["blueprint-string"]["blueprint-string-text"]
	local data = trim(textbox.text)
	if (data == "") then
		player.print({ "no-string" })
		return
	end

	local blueprint_format = BlueprintString.fromString(data)
	if (not blueprint_format or type(blueprint_format) ~= "table") then
		textbox.text = ""
		player.print({ "unknown-format" })
		return
	end

	local blueprint = nil
	local book = nil
	local active = nil
	local main = nil
	if (not blueprint_format.book) then
		-- Blueprint
		if (holding_book(player)) then
			player.print({ "need-blueprint" })
			return
		end

		blueprint = find_empty_blueprint(player)
		if (not blueprint) then
			player.print({ "no-empty-blueprint" })
			return
		end
	else
		-- Blueprint Book
		if (type(blueprint_format.book) ~= "table") then
			textbox.text = ""
			player.print({ "unknown-format" })
			return
		end

		if (holding_blueprint(player)) then
			player.print({ "need-blueprint-book" })
			return
		end

		local page_count = 0
		for _, page in pairs(blueprint_format.book) do
			page_count = page_count + 1
		end
		if (page_count < 1) then
			textbox.text = ""
			player.print({ "unknown-format" })
			return
		end

		local slots = math.min(page_count, game.item_prototypes["blueprint-book"].inventory_size + 1)
		book = find_empty_book(player, slots)
		if (not book) then
			player.print({ "no-empty-blueprint" })
			return
		end

		active = book.get_inventory(defines.inventory.item_active)
		main = book.get_inventory(defines.inventory.item_main)

		local advanced_circuits = slots - active.get_item_count("blueprint") - main.get_item_count("blueprint")
		if (advanced_circuits > player.get_item_count("advanced-circuit")) then
			player.print({ "need-advanced-circuit", advanced_circuits })
			return
		end

		if (advanced_circuits > 0) then
			player.remove_item { name = "advanced-circuit", count = advanced_circuits }
		end

		-- Create the required blueprints
		if (blueprint_format.book[1]) then
			active[1].set_stack("blueprint")
		else
			active[1].clear()
		end
		for i = 1, #main do
			if (blueprint_format.book[i + 1]) then
				main[i].set_stack("blueprint")
			else
				main[i].clear()
			end
		end

		-- If we have extra blueprints, put them back in
		local extra_blueprints = -advanced_circuits
		if (extra_blueprints > 0 and not active[1].valid_for_read) then
			active[1].set_stack("blueprint")
			extra_blueprints = extra_blueprints - 1
		end
		for i = 1, #main do
			if (extra_blueprints > 0 and not main[i].valid_for_read) then
				main[i].set_stack("blueprint")
				extra_blueprints = extra_blueprints - 1
			end
		end
	end

	textbox.text = ""

	-- Blueprint
	if (not book) then
		local error = load_blueprint_data(blueprint, blueprint_format)
		if (error) then
			player.print(error)
		end
		return
	end

	-- Blueprint Book
	if (blueprint_format.book[1]) then
		local error = load_blueprint_data(active[1], blueprint_format.book[1])
		if (error and error[1] ~= "unknown-format") then
			player.print(error)
		end
	end
	for i = 1, #main do
		if (blueprint_format.book[i + 1]) then
			local error = load_blueprint_data(main[i], blueprint_format.book[i + 1])
			if (error and error[1] ~= "unknown-format") then
				player.print(error)
			end
		end
	end
	book.label = blueprint_format.name or ""
end

local duplicate_filenames
-- Fix incorrect file name
local function fix_filename(player, filename)
	if (#game.players > 1 and player.name and player.name ~= "") then
		local name = player.name
		filename = name .. "-" .. filename
	end

	filename = filename:gsub("[/\\:*?\"<>|]", "_")

	local lowercase = filename:lower()
	if (duplicate_filenames[lowercase]) then
		duplicate_filenames[lowercase] = duplicate_filenames[lowercase] + 1
		filename = filename .. "-" .. duplicate_filenames[lowercase]
	else
		duplicate_filenames[lowercase] = 1
	end

	return filename
end

local blueprints_saved
-- Save blueprint as file
local function blueprint_to_file(player, stack, filename)
	local blueprint_format = {
		entities = stack.get_blueprint_entities(),
		tiles = stack.get_blueprint_tiles(),
		icons = stack.blueprint_icons,
		name = stack.label,
	}

	local data = BlueprintString.toString(blueprint_format)
	filename = fix_filename(player, filename)
	game.write_file("blueprint-string/" .. filename .. ".txt", data, false, player.index)
	blueprints_saved = blueprints_saved + 1
end

-- Save blueprint book as file
local function book_to_file(player, book, filename)
	local blueprint_format = { book = {} }

	for position, stack in pairs(book_inventory(book)) do
		if (stack.is_blueprint_setup()) then
			blueprint_format.book[position] = {
				entities = stack.get_blueprint_entities(),
				tiles = stack.get_blueprint_tiles(),
				icons = stack.blueprint_icons,
				name = stack.label,
			}
		end
	end
	if (book.label) then
		blueprint_format.name = book.label
	end

	local data = BlueprintString.toString(blueprint_format)
	filename = fix_filename(player, filename)
	game.write_file("blueprint-string/" .. filename .. ".txt", data, false, player.index)
	blueprints_saved = blueprints_saved + 1
end

local function save_blueprint_as(player, filename)
	blueprints_saved = 0
	duplicate_filenames = {}

	if (not holding_valid_blueprint(player) and not holding_book(player)) then
		player.print({ "no-blueprint-in-hand" })
		return
	end

	if (not filename or filename == "") then
		player.print({ "no-filename" })
		return
	end

	filename = filename:sub(1, 100)

	if (player.cursor_stack.type == "blueprint") then
		blueprint_to_file(player, player.cursor_stack, filename)
	elseif (player.cursor_stack.type == "blueprint-book") then
		book_to_file(player, player.cursor_stack, filename)
	end

	local prompt = player.gui.center["blueprint-string-filename-prompt"]
	if (prompt) then prompt.destroy() end

	if (blueprints_saved > 0) then
		player.print({ "blueprint-saved-as", filename })
	else
		player.print({ "blueprints-not-saved" })
	end
end

local function save_blueprint(player)
	if (not holding_valid_blueprint(player) and not holding_book(player)) then
		player.print({ "no-blueprint-in-hand" })
		return
	end

	if (player.cursor_stack.label) then
		save_blueprint_as(player, player.cursor_stack.label)
	else
		bps_prompt_for_filename(player)
	end
end

local function save_all(player)
	blueprints_saved = 0
	duplicate_filenames = {}

	local main = player.get_inventory(defines.inventory.player_main)
	local quickbar = player.get_inventory(defines.inventory.player_quickbar)

	for position, stack in pairs(filter(quickbar, "blueprint")) do
		if (stack.is_blueprint_setup()) then
			local filename = "toolbar-" .. position
			if (stack.label) then
				filename = stack.label
			end
			blueprint_to_file(player, stack, filename)
		end
	end

	for position, stack in pairs(filter(main, "blueprint")) do
		if (stack.is_blueprint_setup()) then
			local filename = "inventory-" .. position
			if (stack.label) then
				filename = stack.label
			end
			blueprint_to_file(player, stack, filename)
		end
	end

	for position, stack in pairs(filter(quickbar, "blueprint-book")) do
		local filename = "toolbar-" .. position
		if (stack.label) then
			filename = stack.label
		end
		book_to_file(player, stack, filename)
	end

	for position, stack in pairs(filter(main, "blueprint-book")) do
		local filename = "inventory-" .. position
		if (stack.label) then
			filename = stack.label
		end
		book_to_file(player, stack, filename)
	end

	if (blueprints_saved > 0) then
		player.print({ "blueprints-saved", blueprints_saved })
	else
		player.print({ "blueprints-not-saved" })
	end
end

function bps_prompt_for_filename(player)
	local frame = player.gui.center["blueprint-string-filename-prompt"]
	if (frame) then
		frame.destroy()
	end

	frame = player.gui.center.add { type = "frame", direction = "vertical", name = "blueprint-string-filename-prompt" }
	local line1 = frame.add { type = "flow", direction = "horizontal" }
	line1.add { type = "label", caption = { "save-as" } }
	frame.add { type = "textfield", name = "blueprint-string-filename" }
	local line2 = frame.add { type = "flow", direction = "horizontal" }
	line2.add { type = "button", name = "blueprint-string-filename-save", caption = { "save" }, font_color = white }
	line2.add { type = "button", name = "blueprint-string-filename-cancel", caption = { "cancel" }, font_color = white }
end

-- Check a blueprint for a certain entity
-- @param blueprint blueprint to check
-- @param entities array of entities to check
-- @return bool blueprint contains entity
local function contains_entities(blueprint, entities)
	if not blueprint.entities then
		return false
	end

	for _, e in pairs(blueprint.entities) do
		if entities[e.name] then
			return true
		end
	end

	return false
end

local function upgrade_blueprint(player)
	if (not holding_valid_blueprint(player)) then
		player.print({ "no-blueprint-in-hand" })
		return
	end
	local entities = player.cursor_stack.get_blueprint_entities()
	local tiles = player.cursor_stack.get_blueprint_tiles()

	local offset = { x = -0.5, y = -0.5 }
	local rail_entities = {}
	rail_entities["straight-rail"] = true
	rail_entities["curved-rail"] = true
	rail_entities["rail-signal"] = true
	rail_entities["rail-chain-signal"] = true
	rail_entities["train-stop"] = true
	rail_entities["smart-train-stop"] = true
	if contains_entities(entities, rail_entities) then
		offset = { x = -1, y = -1 }
	end

	if (entities) then
		for _, entity in pairs(entities) do
			entity.position = { x = entity.position.x + offset.x, y = entity.position.y + offset.y }
		end
		player.cursor_stack.set_blueprint_entities(entities)
	end
	if (tiles) then
		for _, entity in pairs(tiles) do
			tile.position = { x = tile.position.x + offset.x, y = tile.position.y + offset.y }
		end
		player.cursor_stack.set_blueprint_tiles(tiles)
	end
end

-- Handle GUI click
function bps_on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if (name == "blueprint-string-load") then
		load_blueprint(player)
	elseif (name == "blueprint-string-save-all") then
		save_all(player)
	elseif (name == "blueprint-string-save") then
		save_blueprint(player)
	elseif (name == "blueprint-string-filename-save") then
		save_blueprint_as(player, player.gui.center["blueprint-string-filename-prompt"]["blueprint-string-filename"].text)
	elseif (name == "blueprint-string-filename-cancel") then
		player.gui.center["blueprint-string-filename-prompt"].destroy()
	elseif (name == "blueprint-string-button") then
		expand_gui(player)
	elseif (name == "blueprint-string-upgrade") then
		upgrade_blueprint(player)
	end
end

function bps_on_robot_built_entity(event)
	local entity = event.created_entity
	if (entity and entity.type == "assembling-machine" and entity.recipe and not entity.recipe.enabled) then
		entity.recipe = nil
	end
end


-- Event.register(-1, bps_init)
-- Event.register(defines.events.on_player_created, player_joined)
-- Event.register(defines.events.on_research_finished, on_research_finished)
-- Event.register(defines.events.on_gui_click, on_gui_click)
-- Event.register(defines.events.on_robot_built_entity, on_robot_built_entity)