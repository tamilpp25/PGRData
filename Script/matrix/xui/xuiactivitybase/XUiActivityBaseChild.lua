local next = next
local tableInsert = table.insert

local XUiPanelTask = require("XUi/XUiActivityBase/XUiPanelTask")
local XUiPanelShop = require("XUi/XUiActivityBase/XUiPanelShop")
local XUiPanelSkip = require("XUi/XUiActivityBase/XUiPanelSkip")
local XUiPanelLink = require("XUi/XUiActivityBase/XUiPanelLink")
local XUiPanelSendInvitation = require("XUi/XUiActivityBase/XUiPanelSendInvitation")
local XUiPanelAcceptInvitation = require("XUi/XUiActivityBase/XUiPanelAcceptInvitation")
local XUiJigsawPuzzle = require("XUi/XUiActivityBase/XUiJigsawPuzzle")
local XUiConsumeReward = require("XUi/XUiActivityBase/XUiConsumeReward")
local XUiScratchTicket = require("XUi/XUiActivityBase/XUiScratchTicket")
local BTN_INDEX = {
    First = 1,
    Second = 2,
}

local XUiActivityBaseChild = XLuaUiManager.Register(XLuaUi, "UiActivityBaseChild")

function XUiActivityBaseChild:OnStart(activityGroupInfos, selectIndex, selectId)
    local isAcitivityOpen = next(activityGroupInfos) ~= nil
    self.PaneNothing.gameObject:SetActiveEx(not isAcitivityOpen)
    self.ScrollTitleTab.gameObject:SetActiveEx(isAcitivityOpen)
    self.PanelRightContent.gameObject:SetActiveEx(isAcitivityOpen)
    self.RImgContentBg.gameObject:SetActiveEx(isAcitivityOpen)
    if not isAcitivityOpen then return end
    self.PanelLoadPrefabList = {
        self.PanelLoadPrefab1,
        self.PanelLoadPrefab2,
    }
    self.PanelDic = {}
    self.UnusedLoadPrefabIndex = 1
    self.AcitivityTypeGroups = {}
    self.ActivityGroupInfos = activityGroupInfos
    self:UpdateActivityInfos(selectIndex, selectId)
    XRedPointManager.AddRedPointEvent(self.PanelNoticeTitleBtnGroup, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITIES_TOGS }, nil, false)
end

function XUiActivityBaseChild:OnEnable()
    if self.SelectIndex then
        self.PanelNoticeTitleBtnGroup:SelectIndex(self.SelectIndex)
    end
end

function XUiActivityBaseChild:OnDisable()
    if self.SelectedPanel and self.SelectedPanel.OnDisable then
        self.SelectedPanel:OnDisable()
    end
    self:StopDelayUpdateTaskPanelTimer()
end

function XUiActivityBaseChild:OnDestroy()
    if self.ShopPanel then
        self.ShopPanel:OnDestroy()
    end
    if self.PanelDic and next(self.PanelDic) then
        for _, panel in pairs(self.PanelDic) do
            if panel.OnDestroy then
                panel:OnDestroy()
            end
        end
    end
end

function XUiActivityBaseChild:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_ACTIVITY_INFO_UPDATE, XEventId.EVENT_TASK_SYNC }
end

function XUiActivityBaseChild:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_FINISH_TASK then
        self.AutoRefresh = true
        self.PanelNoticeTitleBtnGroup:SelectIndex(self.SelectIndex)
    elseif evt == XEventId.EVENT_ACTIVITY_INFO_UPDATE then
        if next(self.AcitivityTypeGroups[args[1]]) then
            self:OnCheckRedPointByType(args[1])
        end
        local panel = self.SelectedPanel
        if panel.UpdateInfo then 
            panel:UpdateInfo()
        end
    elseif evt == XEventId.EVENT_TASK_SYNC then
        --通知过多导致频繁刷新，延迟刷新防卡顿
        if self.DelayUpdateTaskPanelTimer then
            return
        end

        self.DelayUpdateTaskPanelTimer = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end

            local panel = self.SelectedPanel
            if panel.UpdateTask then 
                panel:UpdateTask()
            end
            self:StopDelayUpdateTaskPanelTimer()
        end, 50)
    end
end

function XUiActivityBaseChild:StopDelayUpdateTaskPanelTimer()
    if self.DelayUpdateTaskPanelTimer then
        XScheduleManager.UnSchedule(self.DelayUpdateTaskPanelTimer)
        self.DelayUpdateTaskPanelTimer = nil
    end
end

-- 只刷新tog红点不刷新界面
function XUiActivityBaseChild:OnCheckRedPoint(index, id)
    index = index or self.SelectIndex 
    id = id or self.SelectActvityId
    if not index or not id then return end

    local uiButton = self.TabBtns[index]
    local needRedPoint = XDataCenter.ActivityManager.CheckRedPointByActivityId(id)
    uiButton:ShowReddot(needRedPoint)

    local subGroupIndex = uiButton.SubGroupIndex
    if subGroupIndex and self.TabBtns[subGroupIndex] then
        local needRed = false
        for _, btn in pairs(self.TabBtns) do
            if btn.SubGroupIndex and btn.SubGroupIndex == subGroupIndex
            and btn.ReddotObj.activeSelf then
                needRed = true
                break
            end
        end
        self.TabBtns[subGroupIndex]:ShowReddot(needRed)
    end
end

-- 刷新该活动类型的tog红点
function XUiActivityBaseChild:OnCheckRedPointByType(type)
    if not type then return end
    local typeGroup = self.AcitivityTypeGroups[type]
    if not typeGroup then return end
    for k, v in pairs(typeGroup) do
        self:OnCheckRedPoint(v.BtnIndex, v.ActId)
    end
end

function XUiActivityBaseChild:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiActivityBaseChild:UpdateActivityInfos(selectIndex, selectId)
    self.AcitivityIndexDic = {}
    self:UpdateLeftTabBtns(selectIndex, selectId)
end

function XUiActivityBaseChild:UpdateLeftTabBtns(selectIndex, selectId)
    self.TabBtns = {}
    local btnIndex = 0
    local selectIdToIndex = selectIndex
    local firstRedPointIndex

    --一级标题
    for groupId, activityGroupInfo in ipairs(self.ActivityGroupInfos) do
        local activityGroupCfg = activityGroupInfo.ActivityGroupCfg
        local activityCfgs = activityGroupInfo.ActivityCfgs
        local numOfActivityCfgs = #activityCfgs

        local btnModel = self:GetCertainBtnModel(BTN_INDEX.First, numOfActivityCfgs > 1)
        local btn = CS.UnityEngine.Object.Instantiate(btnModel)
        btn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        btn.gameObject:SetActiveEx(true)
        btn:SetName(activityGroupCfg.Name)

        local bg1 = btn.transform:FindTransform("RImgBg1")
        if bg1 then bg1:GetComponent("RawImage"):SetRawImage(activityGroupCfg.Bg) end
        local bg2 = btn.transform:FindTransform("RImgBg2")
        if bg2 then bg2:GetComponent("RawImage"):SetRawImage(activityGroupCfg.Bg) end
        local bg3 = btn.transform:FindTransform("RImgBg3")
        if bg3 then bg3:GetComponent("RawImage"):SetRawImage(activityGroupCfg.Bg) end

        local uiButton = btn:GetComponent("XUiButton")
        tableInsert(self.TabBtns, uiButton)
        btnIndex = btnIndex + 1
        local firstNeedRed = false

        --二级标题
        local needRedPoint
        local firstIndex = btnIndex
        local onlyOne = numOfActivityCfgs == 1
        for activityIndex, activityCfg in ipairs(activityCfgs) do
            needRedPoint = XDataCenter.ActivityManager.CheckRedPointByActivityId(activityCfg.Id)
            if not onlyOne then
                local tmpBtnModel = self:GetCertainBtnModel(BTN_INDEX.Second, nil, activityIndex, numOfActivityCfgs)
                local tmpBtn = CS.UnityEngine.Object.Instantiate(tmpBtnModel)
                tmpBtn:SetName(activityCfg.Name)
                tmpBtn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
                tmpBtn.gameObject:SetActiveEx(true)

                local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                tmpUiButton.SubGroupIndex = firstIndex
                tableInsert(self.TabBtns, tmpUiButton)
                btnIndex = btnIndex + 1

                if needRedPoint then
                    tmpUiButton:ShowReddot(true)
                    if not firstRedPointIndex then
                        firstRedPointIndex = btnIndex
                    end
                    firstNeedRed = true
                else
                    tmpUiButton:ShowReddot(false)
                end
            else
                firstNeedRed = needRedPoint
                if needRedPoint then
                    if not firstRedPointIndex then
                        firstRedPointIndex = btnIndex
                    end
                end
            end

            local activityIndexInfo = {
                ActivityIndex = activityIndex,
                GroupId = groupId
            }
            self.AcitivityIndexDic[btnIndex] = activityIndexInfo
            if activityCfg.Id == selectId then
                selectIdToIndex = btnIndex
            end
            if not self.AcitivityTypeGroups[activityCfg.ActivityType] then
                self.AcitivityTypeGroups[activityCfg.ActivityType] = {}
            end
            tableInsert(self.AcitivityTypeGroups[activityCfg.ActivityType] ,{BtnIndex = btnIndex, ActId = activityCfg.Id})
        end
        uiButton:ShowReddot(firstNeedRed)
    end

    self.PanelNoticeTitleBtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
    self.SelectIndex = selectIdToIndex or selectIndex or firstRedPointIndex or 1
end

function XUiActivityBaseChild:OnSelectedTog(index)
    self.SelectIndex = index

    local activityIndexInfo = self.AcitivityIndexDic[index]
    if not activityIndexInfo or not next(activityIndexInfo) then
        return
    end
    local groupId = activityIndexInfo.GroupId
    local activityIndex = activityIndexInfo.ActivityIndex
    local activityGroupInfo = self.ActivityGroupInfos[groupId]
    local activityCfgs = activityGroupInfo.ActivityCfgs
    local activityCfg = activityCfgs[activityIndex]
    self.SelectActvityId = activityCfg.Id

    if self.SelectedPanel then
        if self.SelectedPanel.OnDisable then
            self.SelectedPanel:OnDisable()
        end
        self.SelectedPanel.GameObject:SetActiveEx(false)
    end
    --刷新右边UI
    if activityCfg.ActivityType == XActivityConfigs.ActivityType.Task then
        self.PanelTask.gameObject:SetActiveEx(true)
        self:UpdatePanelTask(activityCfg)
        self.SelectedPanel = self.TaskPanel
    elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Shop then
        self.PanelShop.gameObject:SetActiveEx(true)
        self:UpdatePanelShop(activityCfg)
        self.SelectedPanel = self.ShopPanel
    elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Skip then
        self.PanelSkip.gameObject:SetActiveEx(true)
        self:UpdatePanelSkip(activityCfg)
        self.SelectedPanel = self.SkipPanel
    elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Link then
        self.PanelReward.gameObject:SetActiveEx(true)
        self:UpdatePanelLink(activityCfg)
        self.SelectedPanel = self.LinkPanel
    else
        self:UpdatePanel(activityCfg)
    end

    if activityCfg.ActivityBgType == XActivityConfigs.ActivityBgType.Image then
        self.SpineRoot.gameObject:SetActiveEx(false)
        self.RImgContentBg.gameObject:SetActiveEx(true)
        self.RImgContentBg:SetRawImage(activityCfg.ActivityBg)
    elseif activityCfg.ActivityBgType == XActivityConfigs.ActivityBgType.Spine then
        self.SpineRoot.gameObject:SetActiveEx(true)
        self.RImgContentBg.gameObject:SetActiveEx(false)
        self.SpineRoot:LoadPrefab(activityCfg.ActivityBg)
    else
        self.SpineRoot.gameObject:SetActiveEx(false)
        self.RImgContentBg.gameObject:SetActiveEx(true)
        self.RImgContentBg:SetRawImage(activityCfg.ActivityBg)
    end

    --刷新小红点
    if activityCfg.ActivityType == XActivityConfigs.ActivityType.SendInvitation then
        XDataCenter.RegressionManager.HandleReadSendInvitationActivity()
    elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.AcceptInvitation then
        XDataCenter.RegressionManager.HandleReadAcceptInvitationActivity()
    elseif activityCfg.ActivityType == XActivityConfigs.ActivityType.Link then
        XDataCenter.ActivityManager.HandleLinkActivityRedPoint(activityCfg.Id)
    else
        XDataCenter.ActivityManager.SaveInGameNoticeReadList(activityCfg.Id)
    end

    local uiButton = self.TabBtns[index]
    local needRedPoint = XDataCenter.ActivityManager.CheckRedPointByActivityId(activityCfg.Id)
    uiButton:ShowReddot(needRedPoint)

    --判断一级按钮小红点
    local subGroupIndex = uiButton.SubGroupIndex
    if subGroupIndex and self.TabBtns[subGroupIndex] then
        local needRed = false
        for _, btn in pairs(self.TabBtns) do
            if btn.SubGroupIndex and btn.SubGroupIndex == subGroupIndex
            and btn.ReddotObj.activeSelf then
                needRed = true
                break
            end
        end
        self.TabBtns[subGroupIndex]:ShowReddot(needRed)
    end

    if not self.AutoRefresh then
        self:PlayAnimation("QieHuanTwo", function()
            XLuaUiManager.SetMask(false)
            self:OnAnimFinished(activityCfg)
        end, function()
            XLuaUiManager.SetMask(true)
            self:OnAnimBegin(activityCfg)
        end)
    else
        self.AutoRefresh = nil
    end
end

function XUiActivityBaseChild:UpdatePanelTask(activityCfg)
    self.TaskPanel = self.TaskPanel or XUiPanelTask.New(self.PanelTask.gameObject, self)
    self.TaskPanel:Refresh(activityCfg)
end

function XUiActivityBaseChild:UpdatePanelShop(activityCfg)
    self.ShopPanel = self.ShopPanel or XUiPanelShop.New(self.PanelShop.gameObject, self)
    self.ShopPanel:Refresh(activityCfg)
end

function XUiActivityBaseChild:UpdatePanelSkip(activityCfg)
    self.SkipPanel = self.SkipPanel or XUiPanelSkip.New(self.PanelSkip.gameObject)
    self.SkipPanel:Refresh(activityCfg)
end

function XUiActivityBaseChild:UpdatePanelLink(activityCfg)
    self.LinkPanel = self.LinkPanel or XUiPanelLink.New(self.PanelReward.gameObject, self)
    self.LinkPanel:Refresh(activityCfg)
end

function XUiActivityBaseChild:UpdatePanel(activityCfg)
    local assetPath = activityCfg.ActivityPrefabPath
    if not assetPath then return end
    local type = activityCfg.ActivityType

    if not self.PanelDic[type] then
        local panelLoadPrefab = self.PanelLoadPrefabList[self.UnusedLoadPrefabIndex]
        if not panelLoadPrefab then
            XLog.Error("PanelLoadPrefab is not engough, you need to mod the asset in res")
            return
        end
        local panelGameObject = panelLoadPrefab:LoadPrefab(assetPath)
        self.UnusedLoadPrefabIndex = self.UnusedLoadPrefabIndex + 1
        if type == XActivityConfigs.ActivityType.SendInvitation then
            self.PanelDic[type] = XUiPanelSendInvitation.New(panelGameObject, self)
        elseif type == XActivityConfigs.ActivityType.AcceptInvitation then
            self.PanelDic[type] = XUiPanelAcceptInvitation.New(panelGameObject, self)
        elseif type == XActivityConfigs.ActivityType.JigsawPuzzle then
            self.PanelDic[type] = XUiJigsawPuzzle.New(panelGameObject, self)
        elseif type == XActivityConfigs.ActivityType.ConsumeReward then
            self.PanelDic[type] = XUiConsumeReward.New(panelGameObject, self)
        elseif type == XActivityConfigs.ActivityType.ScratchTicket then
            self.PanelDic[type] = XUiScratchTicket.New(panelGameObject, self)
        elseif type == XActivityConfigs.ActivityType.ScratchTicketGolden then
            self.PanelDic[type] = XUiScratchTicket.New(panelGameObject, self)
        end
    end

    if self.PanelDic[type] then
        local selectedPanel = self.PanelDic[type]
        selectedPanel.GameObject:SetActiveEx(true)
        selectedPanel:Refresh(activityCfg)
        self.SelectedPanel = selectedPanel
    else
        -- 进入此处说明未用ClassName.New(panelGameObject)对gameObject进行初始化
        XLog.Error("you need to use ClassName.New(panelGameObject) in this activityType, activityType is " .. type)
    end
end

function XUiActivityBaseChild:OnAnimFinished(activityCfg)
    local type = activityCfg.ActivityType
    local panel = self.PanelDic[type] 
    if not panel then
        return 
    end
    if panel.OnAnimFinished then
        panel:OnAnimFinished()
    end
end

function XUiActivityBaseChild:OnAnimBegin(activityCfg)
    local type = activityCfg.ActivityType
    local panel = self.PanelDic[type] 
    if not panel then
        return 
    end
    if panel.OnAnimBegin then
        panel:OnAnimBegin()
    end
end