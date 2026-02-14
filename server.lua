lib.callback.register('tactical_lite:canThrow', function(source, itemName)
    if not itemName or type(itemName) ~= 'string' then return false end

    local isValid = false
    for _, cfg in ipairs(Config.QuickThrow.Throwables) do
        if cfg.item == itemName then isValid = true break end
    end

    if not isValid then return false end

    local count = exports.ox_inventory:Search(source, 'count', itemName)
    if count and count > 0 then
        local success = exports.ox_inventory:RemoveItem(source, itemName, 1)
        return success ~= false
    end
    
    return false
end)
