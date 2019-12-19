Compat = Compat or {}


function Compat.handle_factoriomaps()
	if remote.interfaces.factoriomaps then
		script.on_event(remote.call("factoriomaps", "get_start_capture_event_id"), function() 

			print("Starting factoriomaps-oarc integration script")
		
			remote.call("factoriomaps", "surface_set_default", "oarc")

		end)
	end
end