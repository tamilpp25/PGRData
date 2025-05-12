---@class XUiDlcMultiPlayerGiftLevel
---@field ImgProgress UnityEngine.UI.Image
---@field TxtExp UnityEngine.UI.Text
---@field ImgExpIcon UnityEngine.UI.RawImage
---@field TxtLevel UnityEngine.UI.Text
---@field TxtLevelTitle UnityEngine.UI.Text
local XUiDlcMultiPlayerGiftLevel = XClass(XUiNode, "XUiDlcMultiPlayerGiftLevel")

function XUiDlcMultiPlayerGiftLevel:OnStart()
    self.TxtLevelTitle.text = XUiHelper.GetText("MultiMouseHunterBPLevel")
    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    self.ImgExpIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(activityConfig.BpExpItem))

    self._AnimTimer = nil
    self._StartAnimExp = 0
    self._StartAnimLevel = 0
end

function XUiDlcMultiPlayerGiftLevel:OnEnable()
    --注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.DlcMultiplayerBpExp, self._Refresh, self)

    self:_Refresh(nil, nil, true)
end

function XUiDlcMultiPlayerGiftLevel:OnDisable()
    --移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS, self._Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.DlcMultiplayerBpExp, self._Refresh, self)

    self:_StopExpTween()
end

function XUiDlcMultiPlayerGiftLevel:_Refresh(id, count, isImmediately)
    self:_StopExpTween()
    if isImmediately then
        local level = self._Control:GetBpLevel()
        local curExp, upgradeExp = self:GetBpUpgradeExp(level)
        self.TxtLevel.text = tostring(level)
        self.TxtExp.text = string.format("%d/%d", curExp, upgradeExp)
        self.ImgProgress.fillAmount = curExp / upgradeExp
        self._StartAnimExp = curExp
        self._StartAnimLevel = level
    else
        self._AnimTimer = self:_DoExpTween()
    end
end

--获取Bp下一次升级剩余的经验和下一次升级的经验
function XUiDlcMultiPlayerGiftLevel:GetBpUpgradeExp(level)
    local curExp = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.DlcMultiplayerBpExp).Count
    local configs = self._Control:GetDlcMultiplayerBPConfigs()
    local config = configs[level]
    return curExp, (config and config.Exp or 99999)
end

function XUiDlcMultiPlayerGiftLevel:_StopExpTween()
    if self._AnimTimer then
        XScheduleManager.UnSchedule(self._AnimTimer)
        self._AnimTimer = nil 
    end
end

function XUiDlcMultiPlayerGiftLevel:_DoExpTween()
    local bpConfig = self._Control:GetDlcMultiplayerBPConfigs()[self._StartAnimLevel]
    if not bpConfig then
        self:_Refresh(nil, nil, true)
        return
    end

    local bpLevel = self._Control:GetBpLevel()
    local totalExp = bpConfig.Exp
    local baseExp = self._StartAnimExp
    local reaminExp = 0
    if self._StartAnimLevel < bpLevel then
        reaminExp = totalExp - baseExp
    elseif self._StartAnimLevel == bpLevel then
        reaminExp = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.DlcMultiplayerBpExp).Count - baseExp
    else
        self:_Refresh(nil, nil, true)
        return
    end
    local timeRatio = math.min(1, reaminExp / totalExp)
    local tweenTime = timeRatio * CS.XGame.ClientConfig:GetFloat("PassportSingleAnimaTime")

    return XUiHelper.Tween(tweenTime,
        function(ratio)
            local curExp = math.min(math.ceil(reaminExp * ratio + baseExp), totalExp)
            self._StartAnimExp = curExp
            self.TxtExp.text = string.format("%d/%d", curExp, totalExp)
            self.ImgProgress.fillAmount = curExp / totalExp
        end,
        function()
            if self._StartAnimLevel < bpLevel then
                self._StartAnimLevel = self._StartAnimLevel + 1
                self._StartAnimExp = 0
                self.TxtLevel.text = tostring(self._StartAnimLevel)
                self.TxtExp.text = string.format("%d/%d", 0, totalExp)
                self.ImgProgress.fillAmount = 0
                self._AnimTimer = self:_DoExpTween()
            else
                self:_Refresh(nil, nil, true)
            end
        end)
end

return XUiDlcMultiPlayerGiftLevel