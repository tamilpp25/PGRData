-- 异构阵线2.0心智天赋等级升级界面
local XUiMaverick2LevelUp = XLuaUiManager.Register(XLuaUi, "UiMaverick2LevelUp")

function XUiMaverick2LevelUp:OnAwake()
    self:SetButtonCallBack()
    self:InitTimes()
end

function XUiMaverick2LevelUp:OnStart(oldLv, curLv)
    self.OldLv = oldLv
    self.CurLv = curLv
end

function XUiMaverick2LevelUp:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiMaverick2LevelUp:OnDisable()

end

function XUiMaverick2LevelUp:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiMaverick2LevelUp:Refresh()
    self.TxtOldLevel.text = XUiHelper.GetText("Maverick2TalentLv", self.OldLv)
    self.TxtCurLevel.text = XUiHelper.GetText("Maverick2TalentLv", self.CurLv)

    -- 收集前后属性变化
    local attrConfigs = XMaverick2Configs.GetMaverick2Attribute()
    local attrDic = {}
    if self.OldLv ~= 0 then
        local oldConfig = XMaverick2Configs.GetMaverick2Mental(self.OldLv, true)
        for i, attrId in ipairs(oldConfig.AttrId) do
            if not attrDic[attrId] then
                attrDic[attrId] = {}
                attrDic[attrId].CurValue = 0
                attrDic[attrId].Order = attrConfigs[attrId].Order
                attrDic[attrId].Name = attrConfigs[attrId].Name
                attrDic[attrId].ShowType = attrConfigs[attrId].ShowType
            end
            attrDic[attrId].AttrId = attrId
            attrDic[attrId].OldValue = oldConfig.AttrValue[i]
        end
    end
    local curConfig = XMaverick2Configs.GetMaverick2Mental(self.CurLv, true)
    for i, attrId in ipairs(curConfig.AttrId) do
        if not attrDic[attrId] then
            attrDic[attrId] = {}
            attrDic[attrId].OldValue = 0
            attrDic[attrId].Order = attrConfigs[attrId].Order
            attrDic[attrId].Name = attrConfigs[attrId].Name
            attrDic[attrId].ShowType = attrConfigs[attrId].ShowType
        end
        attrDic[attrId].AttrId = attrId
        attrDic[attrId].CurValue = curConfig.AttrValue[i]
    end

    -- 排序
    self.AttrList = {}
    for _, attr in pairs(attrDic) do
        table.insert(self.AttrList, attr)
    end
    table.sort(self.AttrList, function(a, b)
        return a.Order < b.Order
    end)

    -- 刷新属性列表
    XUiHelper.RefreshCustomizedList(self.Properties, self.PanelProperty1.transform, #self.AttrList, function(index, go)
        self:RefreshAttr(index, go)
    end)
end

-- 刷新属性
function XUiMaverick2LevelUp:RefreshAttr(index, go)
    local attr = self.AttrList[index]
    local uiObj = go:GetComponent("UiObject")
    uiObj:GetObject("InfoName").text = attr.Name
    local isPercent = XMaverick2Configs.AttributeEffectType.Percent == attr.ShowType
    uiObj:GetObject("TxtOldLife").text = isPercent and (attr.OldValue / 100) .. "%" or attr.OldValue
    uiObj:GetObject("TxtCurLife").text = isPercent and (attr.CurValue / 100) .. "%" or attr.CurValue
    local isSame = attr.OldValue == attr.CurValue
    uiObj:GetObject("TxtCurLife").gameObject:SetActiveEx(not isSame)
    uiObj:GetObject("Grow").gameObject:SetActiveEx(not isSame)
end

function XUiMaverick2LevelUp:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.Maverick2Manager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end