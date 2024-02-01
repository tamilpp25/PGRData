---@class XUiPanelRecord : XUiNode
---@field Parent XUiGachaLamiyaLog
local XUiPanelRecord = XClass(XUiNode, "XUiPanelRecord")

function XUiPanelRecord:OnStart()
    self._TypeText = {}
    self:SetTypeText()
end

function XUiPanelRecord:SetTypeText()
    self._TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    self._TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XMVCA.XCharacter:GetCharacterType(templateId)
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            return CS.XTextManager.GetText("TypeCharacter")
        elseif characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
            return CS.XTextManager.GetText("TypeIsomer")
        end
    end
    self._TypeText[XArrangeConfigs.Types.Weapon] = CS.XTextManager.GetText("TypeWeapon")
    self._TypeText[XArrangeConfigs.Types.Wafer] = CS.XTextManager.GetText("TypeWafer")
    self._TypeText[XArrangeConfigs.Types.Fashion] = CS.XTextManager.GetText("TypeFashion")
    self._TypeText[XArrangeConfigs.Types.Furniture] = CS.XTextManager.GetText("TypeFurniture")
    self._TypeText[XArrangeConfigs.Types.HeadPortrait] = CS.XTextManager.GetText("TypeHeadPortrait")
    self._TypeText[XArrangeConfigs.Types.ChatEmoji] = CS.XTextManager.GetText("TypeChatEmoji")
end

function XUiPanelRecord:RefreshUiShow(gachaConfig)
    if self._GachaConfig then
        return
    end

    self._GachaConfig = gachaConfig
    local clearStr = CS.XTextManager.GetText("ClearMinimumGuarantee")
    local notClearStr = CS.XTextManager.GetText("GachaMinCount", XDataCenter.GachaManager.GetMissTimes(gachaConfig.Id), gachaConfig.PropStartTimes)
    self.TxtEnsureCount.text = XDataCenter.GachaManager.IsClearMinimumGuarantee(gachaConfig.Id) and clearStr or notClearStr

    local gachaLogList = XDataCenter.GachaManager.GetGachaLogById(gachaConfig.Id)
    local name
    local quality
    local fromName
    local time
    for _, v in pairs(gachaLogList) do
        if v.RewardGoods.ConvertFrom ~= 0 then
            local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.ConvertFrom)
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = fromGoods.Quality
            quality = quality or 1
            fromName = fromGoods.Name
            if fromGoods.TradeName then
                fromName = string.format("%s.%s", fromName, fromGoods.TradeName)
            end
            name = Goods.Name
            time = XTime.TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(fromName, v.RewardGoods.ConvertFrom, name, time, quality)
        else
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)
            quality = Goods.Quality
            quality = quality or 1
            name = Goods.Name
            if Goods.TradeName then
                name = string.format("%s.%s", name, Goods.TradeName)
            end
            time = XTime.TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(name, v.RewardGoods.TemplateId, nil, time, quality)
        end
    end
end

function XUiPanelRecord:SetLogData(name, templateId, from, time, quality)
    local itemType = XArrangeConfigs.GetType(templateId)
    local go
    if itemType == XArrangeConfigs.Types.Character then
        if quality >= XItemConfigs.Quality.Three then
            go = CS.UnityEngine.Object.Instantiate(self.GridLogHigh, self.PanelContent)
        else
            go = CS.UnityEngine.Object.Instantiate(self.GridLogMid, self.PanelContent)
        end
    else
        if quality == XItemConfigs.Quality.Six then
            go = CS.UnityEngine.Object.Instantiate(self.GridLogHigh, self.PanelContent)
        elseif quality == XItemConfigs.Quality.Five then
            go = CS.UnityEngine.Object.Instantiate(self.GridLogMid, self.PanelContent)
        else
            go = CS.UnityEngine.Object.Instantiate(self.GridLogLow, self.PanelContent)
        end
    end

    local tmpObj = {}
    tmpObj.Transform = go.transform
    tmpObj.GameObject = go.gameObject
    XTool.InitUiObject(tmpObj)
    tmpObj.TxtName.text = name

    if type(self._TypeText[itemType]) == "function" then
        tmpObj.TxtType.text = self._TypeText[itemType](templateId)
    else
        tmpObj.TxtType.text = self._TypeText[itemType]
    end

    if not from then
        tmpObj.TxtTo.gameObject:SetActiveEx(false)
    else
        tmpObj.TxtTo.text = CS.XTextManager.GetText("ToOtherThing", from)
    end
    tmpObj.TxtTime.text = time
    tmpObj.GameObject:SetActiveEx(true)
end

return XUiPanelRecord