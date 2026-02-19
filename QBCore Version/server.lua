local QBCore = exports['qb-core']:GetCoreObject()
lib.callback.register('tactical_lite:canThrow', function(source, itemName)
    if not itemName or type(itemName) ~= 'string' then return false end

    local isValid = false
    for _, cfg in ipairs(Config.QuickThrow.Throwables) do
        if cfg.item == itemName then
            isValid = true; break
        end
    end
    if not isValid then return false end

    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local item = Player.Functions.GetItemByName(itemName)
    if item and item.amount > 0 then
        return Player.Functions.RemoveItem(itemName, 1)
    end
    return false
end)
