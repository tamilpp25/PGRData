local XUiTemple2Util = {}

---@param uiNode XUiNode
function XUiTemple2Util.ActiveIcon(uiNode, data, resetPos)
    if not data then
        XUiTemple2Util._HideAll(uiNode)
        return
    end

    local icon = data.Icon2Instantiate
    if not icon then
        XUiTemple2Util._HideAll(uiNode)
        return
    end

    local color = data.ColorIndex
    local name = icon
    if color and color ~= 0 then
        name = name .. color
    end
    local instantiate = XUiTemple2Util._GetInstantiate(uiNode, name)
    if not instantiate then
        name = icon
        instantiate = XUiTemple2Util._GetInstantiate(uiNode, name)
    end
    if instantiate then
        instantiate.gameObject:SetActiveEx(true)

        if resetPos then
            ---@type UnityEngine.RectTransform
            local rectTransform = instantiate.rectTransform
            rectTransform.anchoredPosition = Vector2.zero
            --print(rectTransform.rect.position)
            --instantiate.transform.localPosition = Vector3.zero
        end

        -- hide others
        for i, obj in pairs(uiNode.IconsInstantiated) do
            if i ~= name then
                obj.gameObject:SetActiveEx(false)
            end
        end
    else
        XUiTemple2Util._HideAll(uiNode)
    end
    return instantiate
end

function XUiTemple2Util._HideAll(uiNode)
    if uiNode.IconsInstantiated then
        for i, obj in pairs(uiNode.IconsInstantiated) do
            obj.gameObject:SetActiveEx(false)
        end
    end
end

---@param uiNode XUiNode
function XUiTemple2Util._GetInstantiate(uiNode, name)
    uiNode.IconsInstantiated = uiNode.IconsInstantiated or {}
    if not uiNode.IconsInstantiated[name] then
        local prefab = uiNode[name]
        if prefab then
            local IconParent = uiNode.IconParent
            if IconParent then
                uiNode.IconsInstantiated[name] = CS.UnityEngine.Object.Instantiate(prefab, IconParent)
                local instantiate = uiNode.IconsInstantiated[name]
                if instantiate then
                    local zero = Vector3.zero
                    instantiate.transform.localPosition = zero
                    instantiate.transform.localEulerAngles = zero
                end
            end
        end
    end
    return uiNode.IconsInstantiated[name]
end

return XUiTemple2Util