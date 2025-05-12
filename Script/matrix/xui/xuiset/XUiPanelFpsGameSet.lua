---@class XUiPanelFpsGameSet : XUiNode 暂停游戏
---@field Parent XUiSet
---@field VideoPlayer XVideoPlayerUGUI
local XUiPanelFpsGameSet = XClass(XUiNode, "XUiPanelFpsGameSet")

function XUiPanelFpsGameSet:OnStart(isHideSetting)
    local weaponBtns = {}
    -- Fps选择武器时需要记录到本地 刚好能直接拿来用
    local weaponIdxs = XSaveTool.GetData(string.format("FpsGameWeapon_%s", XPlayer.Id))
    if XTool.IsTableEmpty(weaponIdxs) then
        -- 从图鉴进入 默认选择全部
        weaponIdxs = { 1, 2, 3, 4 }
    end
    XUiHelper.RefreshCustomizedList(self.GridWeapon.parent, self.GridWeapon, #weaponIdxs, function(index, go)
        local cfg = XMVCA.XFpsGame:GetWeaponById(weaponIdxs[index])
        local weapon = require("XUi/XUiFpsGame/XUiGridFpsGameWeapon").New(go, self, cfg)
        table.insert(weaponBtns, weapon.GridWeapon)
    end)
    self.TabBtnGroup:Init(weaponBtns, function(index)
        self:ShowWeaponDetail(weaponIdxs[index])
    end)
    self.TabBtnGroup:SelectIndex(1)
    self.BtnSetting.gameObject:SetActiveEx(not isHideSetting)
    self.BtnSetting.CallBack = handler(self, self.OnBtnSettingClick)
end

function XUiPanelFpsGameSet:OnEnable()
    if self.VideoPlayer.VideoPlayerInst.player.status == CS.CriWare.CriMana.Player.Status.Pause then
        self.VideoPlayer:Resume()
    end
end

function XUiPanelFpsGameSet:OnDisable()
    if self.VideoPlayer:IsPlaying() then
        self.VideoPlayer:Pause()
    end
end

function XUiPanelFpsGameSet:OnDestroy()
    self.VideoPlayer:Stop()
    self:RemoveTimer()
end

function XUiPanelFpsGameSet:ShowWeaponDetail(weaponId)
    local skillBtns = {}
    self._GridDots = {}
    self._CurWeapon = XMVCA.XFpsGame:GetWeaponById(weaponId)
    local skillCount = #self._CurWeapon.SkillName
    XUiHelper.RefreshCustomizedList(self.GridSkill.parent, self.GridSkill, skillCount, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgSkill:SetRawImage(self._CurWeapon.SkillIcon[index])
        uiObject.TxtType.text = self._CurWeapon.SkillName[index]
        uiObject.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._CurWeapon.SkillDesc[index])
        uiObject.ImgLine.gameObject:SetActiveEx(index < skillCount)
        table.insert(skillBtns, uiObject.GridSkill)
    end)
    self.SkillBtnGroup:Init(skillBtns, function(index)
        self:OnSelectSkill(index)
    end)
    -- 小白点
    XUiHelper.RefreshCustomizedList(self.GridDot.parent, self.GridDot, #self._CurWeapon.SkillName, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        self._GridDots[index] = uiObject
    end)
    self.SkillBtnGroup:SelectIndex(1)
end

function XUiPanelFpsGameSet:OnSelectSkill(index)
    self._VideoIndex = index
    self:RemoveTimer()

    if self.VideoPlayer:IsPlaying() then
        self.VideoPlayer:Stop()
        self._Timer = XScheduleManager.ScheduleForever(function()
            local status = self.VideoPlayer.VideoPlayerInst.player.status
            if status == CS.CriWare.CriMana.Player.Status.Stop or status == CS.CriWare.CriMana.Player.Status.PlayEnd then
                self:RemoveTimer()
                self:PlayVideoSkill()
            end
        end, 1)
    else
        self:PlayVideoSkill()
    end

    self.TxtSkillName.text = self._CurWeapon.SkillName[index]

    for i, uiObject in pairs(self._GridDots) do
        uiObject.ImgOn.gameObject:SetActiveEx(i == index)
        uiObject.ImgOff.gameObject:SetActiveEx(i ~= index)
    end
end

function XUiPanelFpsGameSet:PlayVideoSkill()
    self.VideoPlayer:SetVideoFromRelateUrl(self._CurWeapon.SkillVideoUrl[self._VideoIndex])
    self.VideoPlayer:PrepareThenPlay()
end

function XUiPanelFpsGameSet:OnVideoPlayEnd()
    if self._VideoIndex >= #self._CurWeapon.SkillVideoUrl then
        self._VideoIndex = 1
    else
        self._VideoIndex = self._VideoIndex + 1
    end
    self.VideoPlayer:Stop() -- 这里不Stop没法播新的视频
    self.SkillBtnGroup:SelectIndex(self._VideoIndex)
end

function XUiPanelFpsGameSet:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelFpsGameSet:OnBtnSettingClick()
    self.Parent:JumpToFightSetting()
end

return XUiPanelFpsGameSet