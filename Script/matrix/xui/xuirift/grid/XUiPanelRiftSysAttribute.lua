---@class XUiPanelRiftSysAttribute : XUiNode
local XUiPanelRiftSysAttribute = XClass(XUiNode, "XUiPanelRiftSysAttribute")

function XUiPanelRiftSysAttribute:OnStart(attrId)
    self._AttrId = attrId
    self._GridMap = {}

    local attrs = XDataCenter.RiftManager:GetSystemAttr(attrId)
    if not attrs.Config then
        return
    end
    local datas = {}
    for param, value in pairs(attrs.Values) do
        table.insert(datas, { param, value })
    end
    table.sort(datas, function(a, b)
        return a[1] < b[1]
    end)

    self.TxtTitle1.text = XRiftConfig.GetAttrName(attrId)
    self.TxtTitle2.text = attrs.Config.Desc

    local content = self.GridBuff01.parent
    for i, v in ipairs(datas) do
        local param, value = v[1], v[2]
        local str
        local uiObject = {}
        local go = XUiHelper.Instantiate(i % 2 == 0 and self.GridBuff02 or self.GridBuff01, content)
        go.gameObject:SetActiveEx(true)
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.TxtOnNum1.text = value
        uiObject.TxtOffNum1.text = value
        if attrs.Config.ShowType == XRiftConfig.AttributeFixEffectType.Percent then
            str = string.format("%.1f", param / 100)
            str = string.format("%s%%", self:FormatNum(str))
        else
            str = param
        end
        uiObject.TxtOnNum2.text = str
        uiObject.TxtOffNum2.text = str
        self._GridMap[value] = uiObject
    end
    self.GridBuff01.gameObject:SetActiveEx(false)
    self.GridBuff02.gameObject:SetActiveEx(false)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(content)
end

---@param attributeTemplate XRiftAttributeTemplate
function XUiPanelRiftSysAttribute:SetData(attributeTemplate)
    self._AttributeTemplate = attributeTemplate
end

function XUiPanelRiftSysAttribute:OnEnable()
    if self._AttributeTemplate then
        local level = self._AttributeTemplate:GetAttrLevel(self._AttrId)
        for value, uiObject in pairs(self._GridMap or {}) do
            uiObject.PanelOn.gameObject:SetActiveEx(level >= value)
            uiObject.PanelOff.gameObject:SetActiveEx(level < value)
        end
    end
end

-- 小数如果为0，则去掉
function XUiPanelRiftSysAttribute:FormatNum(num)
    num = tonumber(num)
    local t1, t2 = math.modf(num)
    if t2 > 0 then
        return num
    else
        return t1
    end
end

return XUiPanelRiftSysAttribute