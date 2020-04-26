ESX = nil
local lastPlayerSuccess = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

if Config.MaxInService ~= -1 then
	TriggerEvent('esx_service:activateService', 'taxi', Config.MaxInService)
end

TriggerEvent('esx_phone:registerNumber', 'taxi', _U('taxi_client'), true, true)
TriggerEvent('esx_society:registerSociety', 'taxi', 'Taxi', 'society_taxi', 'society_taxi', 'society_taxi', {type = 'public'})

RegisterNetEvent('esx_taxijob:success')
AddEventHandler('esx_taxijob:success', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local timeNow = os.clock()

	if xPlayer.job.name == 'taxi' then
		if not lastPlayerSuccess[source] or timeNow - lastPlayerSuccess[source] > 5 then
			lastPlayerSuccess[source] = timeNow

			math.randomseed(os.time())
			local total = math.random(Config.NPCJobEarnings.min, Config.NPCJobEarnings.max)
			local societyAccount
			--[[if xPlayer.job.grade >= 3 then
				total = total * 2
			end]]
			
			
			if xPlayer.job.grade == 1 then
				total = total * 1.2
			elseif xPlayer.job.grade == 2 then
				total = total * 1.4
			elseif xPlayer.job.grade == 3 then
				total = total * 1.6
			elseif xPlayer.job.grade == 4 then
				total = total * 2
			else
				total = total
			end


			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_taxi', function(account)
				societyAccount=account	
			end)
			
			if societyAccount then
		
					local playerMoney  = ESX.Math.Round(total * 0.4)
					local societyMoney = ESX.Math.Round(total * 0.6)

					xPlayer.addMoney(playerMoney)
					societyAccount.addMoney(societyMoney)
					--xPlayer.showNotification(_U('comp_earned', societyMoney, playerMoney))
					TriggerClientEvent('esx:showNotification', xPlayer.source, _U('comp_earned', societyMoney, playerMoney))
				else
					xPlayer.addMoney(total)
					--xPlayer.showNotification(_U('have_earned', total))
					TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_earned', total))
				end
			
		end
	else
		print(('[esx_taxijob] [^3WARNING^7] %s attempted to trigger success (cheating)'):format(xPlayer.identifier))
	end
end)

RegisterNetEvent('esx_taxijob:getStockItem')
AddEventHandler('esx_taxijob:getStockItem', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'taxi' then
		TriggerEvent('esx_addoninventory:getSharedInventory', 'society_taxi', function(inventory)
			local item = inventory.getItem(itemName)

			-- is there enough in the society?
			if count > 0 and item.count >= count then
				-- can the player carry the said amount of x item?
				--TriggerClientEvent('esx:showNotification', xPlayer.source, _U('player_cannot_hold'))
				if xPlayer.canCarryItem(itemName, count) then
					inventory.removeItem(itemName, count)
					xPlayer.addInventoryItem(itemName, count)
					--xPlayer.showNotification(_U('have_withdrawn', count, item.label))
					TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_withdrawn', count, item.label))
				else
					--xPlayer.showNotification(_U('player_cannot_hold'))
					TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
				end
			else
				xPlayer.showNotification(_U('quantity_invalid'))
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
			end
		end)
	else
		print(('[esx_taxijob] [^3WARNING^7] %s attempted to trigger getStockItem'):format(xPlayer.identifier))
	end
end)

ESX.RegisterServerCallback('esx_taxijob:getStockItems', function(source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_taxi', function(inventory)
		cb(inventory.items)
	end)
end)







-- 公司自己买车辆机制
ESX.RegisterServerCallback('esx_taxi:getOwnedCars', function(source, cb)
	local ownedCars = {}
	
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', {
			['@owner']  = 'society:taxi',
			['@Type']   = 'car',
			['@job']    = '',
			['@stored'] = true
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
			end
			cb(ownedCars)
		end)

end)

RegisterNetEvent('esx_taxijob:updatestatus')
AddEventHandler('esx_taxijob:updatestatus', function(plate,state)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate,
		
	}, function(rowsChanged)
		--xPlayer.showNotification('車輛已出庫,使用後請及時歸還')
	end)

	
end)









RegisterNetEvent('esx_taxijob:putStockItems')
AddEventHandler('esx_taxijob:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'taxi' then
		TriggerEvent('esx_addoninventory:getSharedInventory', 'society_taxi', function(inventory)
			local item = inventory.getItem(itemName)

			if item.count >= 0 then
				xPlayer.removeInventoryItem(itemName, count)
				inventory.addItem(itemName, count)
				--xPlayer.showNotification(_U('have_deposited', count, item.label))
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_deposited', count, item.label))
			else
				--xPlayer.showNotification(_U('quantity_invalid'))
				TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
			end
		end)
	else
		print(('[esx_taxijob] [^3WARNING^7] %s attempted to trigger putStockItems'):format(xPlayer.identifier))
	end
end)

ESX.RegisterServerCallback('esx_taxijob:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.getInventory())
end)
