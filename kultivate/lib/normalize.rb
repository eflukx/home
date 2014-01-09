# # encoding: UTF-8

# module Kultivatr

# 	require 'time_difference'

# 	def self.normalize(telegrams, group_values = false, group_interval = 10)

# 		if group_values
# 			grouped_values = telegrams.group_by{ |e| e[:timestamp].to_i / (group_interval * 60) }
# 			telegrams = grouped_values.keys.map{ |e| grouped_values[e].last }
# 		end

# 		telegrams.drop(1).map.with_index { |current,index| 

# 			previous = telegrams[index]

# 			# kWh to watts
# 			to_watts = 1 / (TimeDifference.between(previous[:timestamp], current[:timestamp]).in_seconds / 3600) * 1000

# 			delta =->(member) { 
# 				a = current[member]
# 				b = previous[member]
# 				return (a - b) unless a == nil or b == nil
# 			}
		
# 			{
# 				:start_timestamp	=> previous[:timestamp],
# 				:end_timestamp		=> current[:timestamp],
# 				:series => [
# 					{
# 					 	:unit					=> "Watt",
# 						:electra_import_low 	=> delta.(:electra_import_low) 	  * to_watts,
# 						:electra_import_normal 	=> delta.(:electra_import_normal) * to_watts,
# 						:electra_export_low 	=> delta.(:electra_export_low) 	  * to_watts,
# 						:electra_export_normal 	=> delta.(:electra_export_normal) * to_watts,
# 					},
# 					{
# 						:unit					=> "kWh",
# 						:electra_import_low 	=> delta.(:electra_import_low),
# 						:electra_import_normal 	=> delta.(:electra_import_normal),
# 						:electra_export_low 	=> delta.(:electra_export_low),
# 						:electra_export_normal 	=> delta.(:electra_export_normal),
# 					},
# 					{
# 						:unit					=> "m3",
# 						:gas_import				=> delta.(:gas_usage),
# 						:gas_timestamp			=> current[:gas_timestamp],
# 					}
# 				]
# 			}
# 		}
# 	end
# end


