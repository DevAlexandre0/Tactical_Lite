RegisterNetEvent('tactical_lite:throwItem', function(itemName)
    local src = source
    if not itemName or type(itemName) ~= 'string' then return end

    local isValid = false
    for _, cfg in ipairs(Config.QuickThrow.Throwables) do
        if cfg.item == itemName then isValid = true break end
    end

    if isValid then
        local count = exports.ox_inventory:Search(src, 'count', itemName)
        if count and count > 0 then
            exports.ox_inventory:RemoveItem(src, itemName, 1)
        end
    end
end)