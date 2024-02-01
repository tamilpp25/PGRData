--大秘境关卡节点详情 普通
local XUiRiftNormalStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftNormalStageDetail")
local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")

function XUiRiftNormalStageDetail:OnAwake()
    self:InitButton()
    self.GridMonsterDic = {}
end

function XUiRiftNormalStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnBtnResetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
end

function XUiRiftNormalStageDetail:OnStart(layerId, closeCb)
    self.LayerId = layerId
    self.CloseCb = closeCb
end

function XUiRiftNormalStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftNormalStageDetail:RefreshUiShow()
    self.XFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(self.LayerId)
    self.XStageGroup = self.XFightLayer:GetStage()
    -- 关卡信息
    self.TxtStageName.text = self.XStageGroup:GetName()
    self.TxtStageInfo.text = self.XStageGroup:GetDesc()
    -- 赛季信息
    if self.XFightLayer:IsSeasonLayer() then
        self.TxtMatchName.text = XDataCenter.RiftManager:GetSeasonName()
        self.TxtMatchName2.text = XDataCenter.RiftManager:GetSeasonName()
        self:CountDown()
        self.Timer = XScheduleManager.ScheduleForever(function()
            self:CountDown()
        end, XScheduleManager.SECOND, 0)
    else
        self.TxtMatchName.text = ""
        self.TxtMatchName2.text = ""
        self.TxtMatchTime.text = ""
    end
    -- 敌人情报
    -- 刷新前先隐藏
    for k, grid in pairs(self.GridMonsterDic) do
        grid.GameObject:SetActiveEx(false)
    end
    for k, xMonster in ipairs(self.XStageGroup:GetAllEntityMonsters()) do
        local grid = self.GridMonsterDic[k]
        if not grid then
            local trans = CS.UnityEngine.Object.Instantiate(self.GridMonster, self.GridMonster.parent)
            grid = XUiGridRiftMonsterDetail.New(trans)
            self.GridMonsterDic[k] = grid
        end
        grid:Refresh(xMonster, self.XStageGroup)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiRiftNormalStageDetail:OnBtnFightClick()
    local doFun = function ()
        local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId -- 单人只有1个stage
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId
            , XDataCenter.RiftManager.GetSingleTeamData()
            , require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
    end
 
    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftNormalStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftNormalStageDetail:OnBtnResetClick()
    local title = XUiHelper.GetText("TipTitle")
    local content = XUiHelper.GetText("RiftRefreshRandomConfirm")
    local sureCallback = function()
        XDataCenter.RiftManager.RiftStartLayerRequestWithCD(self.XFightLayer:GetId(), function()
            self:RefreshUiShow()
        end)
    end

    if self.XFightLayer:CheckIsOwnFighting() then
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    else
        sureCallback()
    end
end

function XUiRiftNormalStageDetail:OnBtnRewardClick()
    XLuaUiManager.Open("UiRiftPreview", self.XFightLayer)
end

function XUiRiftNormalStageDetail:CountDown()
    local time = XDataCenter.RiftManager:GetSeasonEndTime()
    if time > 0 then
        self.TxtMatchTime.text = XUiHelper.GetText("TurntableTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    end
end

function XUiRiftNormalStageDetail:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer = nil
    self.CloseCb()
end

return XUiRiftNormalStageDetail