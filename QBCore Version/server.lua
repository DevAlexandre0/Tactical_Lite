local QBCore = exports['qb-core']:GetCoreObject()
RegisterNetEvent('tactical_lite:throwItem', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local item = Player.Functions.GetItemByName(itemName)
    if item and item.amount > 0 then
        Player.Functions.RemoveItem(itemName, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], "remove")
    end
end)