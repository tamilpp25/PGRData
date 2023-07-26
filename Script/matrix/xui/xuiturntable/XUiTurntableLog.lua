---@class XUiTurntableLog : XLuaUi
---@field _Control XTurntableControl
local XUiTurntableLog = XLuaUiManager.Register(XLuaUi, "UiTurntableLog")

local TypeText = {}

local Color = {
    [true] = "#FF3C00",
    [false] = "#8E8E8E",
}

function XUiTurntableLog:OnAwake()
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
end

function XUiTurntableLog:OnStart()
    self._Pool = {}
    self._TabButtons = {}
    table.insert(self._TabButtons, self.BtnTab1)
    table.insert(self._TabButtons, self.BtnTab2)
    self.PanelTabTc:Init(self._TabButtons, function(index)
        self:OnSelectTab(index)
    end)
    self.TxtLogCount.text = XUiHelper.GetText("TurntableRecordNum", self._Control:GetRecordNum())
    self:Refresh()
end

function XUiTurntableLog:Refresh()
    self:SetTypeText()
    self.PanelTabTc:SelectIndex(1)

    local records = self._Control:GetGainRecords()
    if #records == 0 then
        self.PanelDisView.gameObject:SetActiveEx(false)
    else
        self.PanelDisView.gameObject:SetActiveEx(true)
        local showCount = math.min(self._Control:GetRecordNum(), #records)
        for i = 1, showCount do
            local v = records[i]
            local cfg = self._Control:GetTurntableById(v.id)
            local cell = self._Pool[i]
            if not cell then
                cell = i == 1 and self.GridLog or XUiHelper.Instantiate(self.GridLog, self.GridLog.parent)
                self._Pool[i] = cell
            end
            cell.gameObject:SetActiveEx(true)

            local itemType = XArrangeConfigs.GetType(v.reward.TemplateId)
            local txtType = ""
            if type(TypeText[itemType]) == "function" then
                txtType = TypeText[itemType](v.reward.TemplateId)
            else
                txtType = TypeText[itemType]
            end

            local txtName = ""
            if v.reward.ConvertFrom ~= 0 then
                local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.reward.ConvertFrom)
                local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.reward.TemplateId)
                txtName = fromGoods.Name
                if fromGoods.TradeName then
                    txtName = txtName .. "." .. fromGoods.TradeName
                end
                txtType = txtType .. XUiHelper.GetText("ToOtherThing", Goods.Name)
            else
                local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.reward.TemplateId)
                txtName = Goods.Name
                if Goods.TradeName then
                    txtName = txtName .. "." .. Goods.TradeName
                end
            end

            local color = Color[cfg.RewardType == 1]
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, cell)
            uiObject.TxtName.text = string.format("<color='%s'>%s</color>", color, txtName)
            uiObject.TxtType.text = string.format("<color='%s'>%s</color>", color, txtType)
            uiObject.TxtTime.text = string.format("<color='%s'>%s</color>", color, XTime.TimestampToGameDateTimeString(v.time))
        end
        for i = showCount + 1, #self._Pool do
            self._Pool[i].gameObject:SetActiveEx(false)
        end
    end

    local data = self._Control:GetRuleDesc()
    self:RefreshTemplateGrids(self.PanelTxt, data, self.PanelTxt.parent, nil, "UiTurntableLogRule", function(grid, data)
        grid.TxtRuleTittle.text = data.title
        grid.TxtRule.text = data.rule
    end)
end

function XUiTurntableLog:OnDestroy()
    self.BtnTanchuangClose.CallBack = nil
end

function XUiTurntableLog:OnSelectTab(index)
    self.Panel1.gameObject:SetActiveEx(index == 1)
    self.Panel2.gameObject:SetActiveEx(index == 2)
end

function XUiTurntableLog:SetTypeText()
    TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XCharacterConfigs.GetCharacterType(templateId)
        if characterType == XCharacterConfigs.CharacterType.Normal then
            return CS.XTextManager.GetText("TypeCharacter")
        elseif characterType == XCharacterConfigs.CharacterType.Isomer then
            return CS.XTextManager.GetText("TypeIsomer")
        end
    end
    TypeText[XArrangeConfigs.Types.Weapon] = CS.XTextManager.GetText("TypeWeapon")
    TypeText[XArrangeConfigs.Types.Wafer] = CS.XTextManager.GetText("TypeWafer")
    TypeText[XArrangeConfigs.Types.Fashion] = CS.XTextManager.GetText("TypeFashion")
    TypeText[XArrangeConfigs.Types.Furniture] = CS.XTextManager.GetText("TypeFurniture")
    TypeText[XArrangeConfigs.Types.HeadPortrait] = CS.XTextManager.GetText("TypeHeadPortrait")
    TypeText[XArrangeConfigs.Types.ChatEmoji] = CS.XTextManager.GetText("TypeChatEmoji")
end

return XUiTurntableLog