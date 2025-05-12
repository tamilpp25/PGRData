local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelLottoPreview
local XUiPanelLottoPreview = XClass(nil, "XUiPanelLottoPreview")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelLottoPreview:Ctor(ui, base, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Base = base
    ---@type XLottoGroupEntity
    self.LottoGroupData = data
    self.RewardCore = {}
    self.RewardFirst = {}
    self.RewardSecond = {}
    self.RewardThird = {}
end

function XUiPanelLottoPreview:UpdateGroupData(data)
    ---@type XLottoGroupEntity
    self.LottoGroupData = data
end

--region V2.6 Kalie
function XUiPanelLottoPreview:UpdateTwoLevelPanel(panelType)
    self:_RefreshKalieReward(self.PanelCore, self.RewardCore, XLottoConfigs.RareLevel.One, panelType)
    self:_RefreshKalieReward(self.PanelSecond, self.RewardFirst, XLottoConfigs.RareLevel.Two, panelType)
    self:_UpdateExReward()
end

---@param uiObject UiObject
---@param rewardGridDir table
function XUiPanelLottoPreview:_RefreshKalieReward(uiObject, rewardGridDir, rareLevel, panelType)
    local drawData = self.LottoGroupData:GetDrawData()
    local rewardDataList = drawData:GetRewardDataList()
    local uiObjDir = {}
    XTool.InitUiObjectByInstance(uiObject, uiObjDir)
    
    local gridCount = 1
    for _, rewardData in pairs(rewardDataList) do
        if rewardData:GetRareLevel() == rareLevel and uiObjDir["Grid"..gridCount] then
            local reward = rewardGridDir[rewardData:GetId()]
            if not reward then
                reward = {
                    Grid = XUiGridCommon.New(self.Base, uiObjDir["Grid"..gridCount]),
                    IsGet = uiObjDir["ImgGet"..gridCount]
                }
                local weaponFashionId = XLottoConfigs.GetLottoClientConfigNumber("WeaponFashionId")
                local fashionDesc = XUiHelper.GetText("LottoKareninaFashionDesc")
                if panelType == XEnumConst.Lotto.Luna then
                    weaponFashionId = XLottoConfigs.GetLottoClientConfigNumber("LunaWeaponFashionId")
                    fashionDesc = XUiHelper.GetText("LottoLunaFashionDesc")
                end
                reward.Grid:SetCustomWeaopnFashionId(weaponFashionId, fashionDesc)
                rewardGridDir[rewardData:GetId()] = reward
            end
            if reward then
                local tmpData = {TemplateId = rewardData:GetTemplateId(), Count = rewardData:GetCount()}
                reward.Grid:Refresh(tmpData, nil, nil, nil, rewardData:GetIsGeted() and 0 or 1)
                reward.IsGet.gameObject:SetActiveEx(rewardData:GetIsGeted())
            end
            gridCount = gridCount + 1
        end
    end
end
--endregion

function XUiPanelLottoPreview:UpdatePanel()
    self:_UpdatePanelTips()
    self:_UpdatePanelReward(self.PanelCore, self.RewardCore, XLottoConfigs.RareLevel.One)
    self:_UpdatePanelReward(self.PanelFirst, self.RewardFirst, XLottoConfigs.RareLevel.Two)
    self:_UpdatePanelReward(self.PanelSecond, self.RewardSecond, XLottoConfigs.RareLevel.Three)
    self:_UpdatePanelReward(self.PanelThird, self.RewardThird, XLottoConfigs.RareLevel.Four)
    self:_UpdateExReward()
end

function XUiPanelLottoPreview:_UpdatePanelTips()
    local hintText = self.LottoGroupData:GetRuleHint()
    self.PanelTips.gameObject:SetActiveEx(hintText)
    self.PanelTips:GetObject("Text").text = hintText or ""
end

function XUiPanelLottoPreview:_UpdatePanelReward(panel, rewardDic, rareLevel)
    local drawData = self.LottoGroupData:GetDrawData()
    local rewardDataList = drawData:GetRewardDataList()
    local gridObj = panel:GetObject("GridRewards")
    local Contents = panel:GetObject("GridContents")
    --local imgGet = self.ExReward:GetObject("ImgGet")
    local isGet = false
    
    gridObj.gameObject:SetActiveEx(false)
    for _,rewardData in pairs(rewardDataList) do
        if rewardData:GetRareLevel() == rareLevel then
            local reward = rewardDic[rewardData:GetId()]
            if not reward then
                local obj = CS.UnityEngine.Object.Instantiate(gridObj, Contents)
                obj.gameObject:SetActiveEx(true)
                reward = XUiGridCommon.New(self.Base, obj)
                rewardDic[rewardData:GetId()] = reward
            end
            if reward then
                local tmpData = {TemplateId = rewardData:GetTemplateId(), Count = rewardData:GetCount()}
                reward:Refresh(tmpData, nil, nil, nil, rewardData:GetIsGeted() and 0 or 1)
                if rewardData:GetIsGeted() then
                    isGet = true
                end
            end
        end
    end
    --if imgGet then
    --    imgGet.gameObject:SetActiveEx(isGet)
    --end
end

function XUiPanelLottoPreview:_UpdateExReward()
    local drawData = self.LottoGroupData:GetDrawData()
    local ExtraRewardId = drawData:GetExtraRewardId()
    self.ExReward.gameObject:SetActiveEx(XTool.IsNumberValid(ExtraRewardId) and true or false)
    if XTool.IsNumberValid(ExtraRewardId) then
        local processText = CS.XTextManager.GetText("LottoExtraRewardProcessText")
        local curCount = math.min(drawData:GetCurRewardCount(),drawData:GetExtraRewardCount())
        local extraCount = drawData:GetExtraRewardCount()
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, self.ExReward)
        local grid = XUiGridCommon.New(self.Base, uiObject.GridRewards)
        local IsGeted = drawData:GetExtraRewardState() == XLottoConfigs.ExtraRewardState.Geted
        local rewardList = XRewardManager.GetRewardList(ExtraRewardId)
        grid:Refresh(rewardList[1], nil, nil, nil, IsGeted and 0 or 1)
        uiObject.TxtCount.text = string.format("%s%d/%d", processText, curCount, extraCount)
        if uiObject.ImgGet then
            uiObject.ImgGet.gameObject:SetActiveEx(IsGeted)
        end
    end
end

return XUiPanelLottoPreview