---@class XUiPanelGachaCanLiverRecord: XUiNode
---@field _Control XGachaCanLiverControl
---@field RootUi XLuaUi
local XUiPanelGachaCanLiverRecord = XClass(XUiNode, "XUiPanelGachaCanLiverRecord")
local TypeText = {}

function XUiPanelGachaCanLiverRecord:OnStart(rootUi)
    self.RootUi = rootUi
    self:SetTypeText()
    self.GridLogHigh.gameObject:SetActiveEx(false)
    self.GridLogMid.gameObject:SetActiveEx(false)
    self.GridLogLow.gameObject:SetActiveEx(false)
end

function XUiPanelGachaCanLiverRecord:SetTypeText()
    TypeText[XArrangeConfigs.Types.Item] = CS.XTextManager.GetText("TypeItem")
    TypeText[XArrangeConfigs.Types.Character] = function(templateId)
        local characterType = XMVCA.XCharacter:GetCharacterType(templateId)
        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            return CS.XTextManager.GetText("TypeCharacter")
        elseif characterType == XEnumConst.CHARACTER.CharacterType.Isomer then
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

function XUiPanelGachaCanLiverRecord:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end

    self.GachaConfig = gachaConfig
    local clearStr = CS.XTextManager.GetText("ClearMinimumGuarantee")
    local notClearStr = CS.XTextManager.GetText("GachaMinCount", XDataCenter.GachaManager.GetMissTimes(gachaConfig.Id), gachaConfig.PropStartTimes)
    self.TxtEnsureCount.text = XDataCenter.GachaManager.IsClearMinimumGuarantee(gachaConfig.Id) and clearStr or notClearStr

    local gachaLogList = XDataCenter.GachaManager.GetGachaLogById(gachaConfig.Id)

    if XTool.IsTableEmpty(gachaLogList) then
        if self.GachaConfig.Id ~= self._Control:GetCurActivityResidentGachaId() then
            -- 如果是限时卡池，尝试请求前一个
            local curIndex = self._Control:GetCurActivityLatestTimelimitGachaIndexById(gachaConfig.Id)
            local lastGachaId = self._Control:GetCurActivityTimelimitGachaIdByIndex(curIndex - 1)

            if XTool.IsNumberValid(lastGachaId) then
                XDataCenter.GachaManager.GetGachaRewardInfoRequest(lastGachaId, function(res)
                    self:RefreshLogShow(XDataCenter.GachaManager.GetGachaLogById(lastGachaId))
                end)
            end
        end
    else
        self:RefreshLogShow(gachaLogList)
    end
end

function XUiPanelGachaCanLiverRecord:RefreshLogShow(gachaLogList)
    local name
    local quality
    local fromName
    local time
    local customQuality
    for _, v in pairs(gachaLogList) do
        customQuality = nil
        -- 自定义品质
        if XTool.IsNumberValid(v.Id) then
            local cfg = XGachaConfigs.GetGachaReward()[v.Id]

            if cfg and not string.IsNilOrEmpty(cfg.Note) then
                customQuality = string.IsNumeric(cfg.Note) and tonumber(cfg.Note) or nil
            end
        end

        if v.RewardGoods.ConvertFrom ~= 0 then
            local fromGoods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.ConvertFrom)
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)

            if XTool.IsNumberValid(customQuality) then
                quality = customQuality
            else
                quality = fromGoods.Quality
                quality = quality or 1
            end

            fromName = fromGoods.Name
            if fromGoods.TradeName then
                fromName =  string.format("%s.%s", fromName,fromGoods.TradeName)
            end
            name = Goods.Name
            time = XTime.TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(fromName, v.RewardGoods.ConvertFrom, name, time, quality, XTool.IsNumberValid(customQuality))
        else
            local Goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(v.RewardGoods.TemplateId)

            if XTool.IsNumberValid(customQuality) then
                quality = customQuality
            else
                quality = Goods.Quality
                quality = quality or 1
            end

            name = Goods.Name
            if Goods.TradeName then
                name = string.format("%s.%s", name,Goods.TradeName)
            end
            time = XTime.TimestampToGameDateTimeString(v.GachaTime)
            self:SetLogData(name, v.RewardGoods.TemplateId, nil, time, quality, XTool.IsNumberValid(customQuality))
        end
    end
end

function XUiPanelGachaCanLiverRecord:SetLogData(name, templateId, from, time, quality, customShow)
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

    if type(TypeText[itemType]) == "function" then
        tmpObj.TxtType.text = TypeText[itemType](templateId)
    else
        tmpObj.TxtType.text = TypeText[itemType]
    end

    if not from then
        tmpObj.TxtTo.gameObject:SetActiveEx(false)
    else
        tmpObj.TxtTo.text = CS.XTextManager.GetText("ToOtherThing", from)
    end
    tmpObj.TxtTime.text = time
    tmpObj.GameObject:SetActiveEx(true)

    if customShow then
        local colorTxt = XGachaConfigs.GetClientConfig('LilithDrawRecordCustomQualityShow', quality)

        if not string.IsNilOrEmpty(colorTxt) then
            local color = XUiHelper.Hexcolor2Color(string.gsub(colorTxt, '#', ''))

            if color then
                tmpObj.TxtTime.color = color
                tmpObj.TxtTo.color = color
                tmpObj.TxtType.color = color
                tmpObj.TxtName.color = color
            end
        end
    end
end

return XUiPanelGachaCanLiverRecord