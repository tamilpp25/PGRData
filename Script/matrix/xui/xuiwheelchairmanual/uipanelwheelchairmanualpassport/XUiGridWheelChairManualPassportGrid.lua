local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelChairManualPassportGrid: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelChairManualPassportGrid = XClass(XUiNode, 'XUiGridWheelChairManualPassportGrid')

---@param rootUi XLuaUi
function XUiGridWheelChairManualPassportGrid:OnStart(rootUi)
    self.GridObjs = {}
    self.RootUi = rootUi
end

function XUiGridWheelChairManualPassportGrid:Refresh(level, commonRewardId, seniorRewardId)
    self.Level = level
    self.CommonRewardId = commonRewardId
    self.SeniorRewardId = seniorRewardId
    self:UpdateLevelPanel()
    self:UpdatePermitPanel()
    self:UpdateRImgLock()
end

--当前等级没到显示黑色遮罩
function XUiGridWheelChairManualPassportGrid:UpdateRImgLock()
    local currLevel = self._Control:GetBpLevel()
    self.RImgLock.gameObject:SetActiveEx(currLevel < self:GetLevel())
end

--刷新物品格子
function XUiGridWheelChairManualPassportGrid:UpdatePermitPanel()
    -- 显示普通手册奖励
    local nextUiIndex = self:_ShowRewardGoodsList(1, self.CommonRewardId, true)
    -- 显示高级手册奖励
    nextUiIndex = self:_ShowRewardGoodsList(nextUiIndex, self.SeniorRewardId, false)
    
    -- 隐藏剩余的奖励
    for i = nextUiIndex, nextUiIndex + 10 do
        local go = self["PanelPermit" .. i]
        if go then
            go.gameObject:SetActiveEx(false)
        else
            break
        end
    end
end

function XUiGridWheelChairManualPassportGrid:_ShowRewardGoodsList(uiIndex, rewardCfgId, isCommon)
    local rewardId = self._Control:GetBPRewardIdById(rewardCfgId)
    local primeList = self._Control:GetBPIsDisplaysById(rewardCfgId)
    local grid
    
    local rewardGoodsList = XRewardManager.GetRewardList(rewardId)
    local isUnLock = isCommon and true or self._Control:GetIsSeniorManualUnLock()

    local isReceiveReward = self._Control:CheckManualRewardIsGet(rewardCfgId)
    local isCanReceiveReward = (not isReceiveReward) and (self:GetLevel() <= self._Control:GetBpLevel()) and isUnLock
    
    for i, rewardData in ipairs(rewardGoodsList) do
        grid = self.GridObjs[uiIndex]
        if self["GridCommonPermit" .. uiIndex] and not grid then
            grid = XUiGridCommon.New(self.RootUi, self["GridCommonPermit" .. uiIndex])
            self.GridObjs[uiIndex] = grid
        end

        if XTool.IsNumberValid(rewardData) then
            if not isReceiveReward and isCanReceiveReward then
                grid:SetClickCallback(function() self:GridOnClick(isCommon) end)
                self:SetGridCommonPermitEffectActive(uiIndex, true)
            else
                grid:AutoAddListener()
                self:SetGridCommonPermitEffectActive(uiIndex, false)
            end

            grid:Refresh(rewardData)
            grid.GameObject:SetActive(true)
        else
            grid.GameObject:SetActive(false)
            self:SetGridCommonPermitEffectActive(uiIndex, false)
        end

        --已领取标志
        local getUi = self["ImgGetOutPermit" .. uiIndex]
        if getUi then
            getUi.gameObject:SetActiveEx(isReceiveReward or false)
        end

        --未解锁标志
        local lockUi = self["ImgLockingPermit" .. uiIndex]
        if lockUi then
            lockUi.gameObject:SetActiveEx(not isUnLock)
            
            local canvasGroup = self["GridCommonPermitCanvasGroup" .. uiIndex]
            if canvasGroup then
                canvasGroup.alpha = isUnLock and 1 or 0.5   --未解锁时半透明
            end
        end

        --贵重奖励
        local isPrimeReward = table.contains(primeList, i)
        
        local primeUi = self["RImgIsPrimeReward" .. uiIndex]
        if primeUi then
            primeUi.gameObject:SetActiveEx(isPrimeReward)
        end

        uiIndex = uiIndex + 1
    end
    
    return uiIndex
end

function XUiGridWheelChairManualPassportGrid:SetGridCommonPermitEffectActive(index, isActive)
    local effectObj = self["GridCommonPermitEffect" .. index]
    if effectObj then
        effectObj.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridWheelChairManualPassportGrid:GridOnClick(isCommon)
    if XMVCA.XWheelchairManual:CheckManualAnyRewardCanGet() then
        XMVCA.XWheelchairManual:RequestWheelchairManualGetManualReward(isCommon and self._Control:GetCurActivityCommanManualId() or self._Control:GetCurActivitySeniorManualId(), function(success, rewardGoodsList)
            if success then
                self.Parent:Refresh()
                self._Control:ShowRewardList(rewardGoodsList)
            end
        end)
    end
end

function XUiGridWheelChairManualPassportGrid:UpdateLevelPanel()
    local mylevel = self:GetLevel()
    local currLevel = self._Control:GetBpLevel()
    local levelDesc = CS.XTextManager.GetText("PassportLevelDesc", mylevel)

    --当前等级
    self.NowLevel.gameObject:SetActiveEx(currLevel == mylevel)
    self.TxtNowLevel.text = levelDesc

    --超过当前等级
    self.ReachLevel.gameObject:SetActiveEx(currLevel > mylevel)
    self.TxtReachLevel.text = levelDesc

    --当前等级未到达
    self.NotreachedLevel.gameObject:SetActiveEx(currLevel < mylevel)
    self.TxtNotReachedLevel.text = levelDesc
end

function XUiGridWheelChairManualPassportGrid:GetLevel()
    return self.Level
end

return XUiGridWheelChairManualPassportGrid