local Object = CS.UnityEngine.Object
local Vector3 = CS.UnityEngine.Vector3
local V3O = Vector3.one

---@class XUiDormSecond : XLuaUi
---@field XUiDormSecondHead XUiDormSecondHead
local XUiDormSecond = XLuaUiManager.Register(XLuaUi, "UiDormSecond")
local XUiDormNameGridItem = require("XUi/XUiDormSecond/XUiDormNameGridItem")
local XUiDormSecondHead = require("XUi/XUiDormSecond/XUiDormSecondHead")
local XUiDormReName = require("XUi/XUiDormSecond/XUiDormReName")
local XUiDormCaress = require("XUi/XUiDormSecond/XUiDormCaress")
local XUiPanelEventShow = require("XUi/XUiDormSecond/XUiPanelEventShow")
local XUiDormBgm = require("XUi/XUiDormSecond/XUiDormBgm")

local TextManager = CS.XTextManager
local SelfPreDormId = -1 --在访问其他人时，记录当前自己的宿舍Id。在访问返回时使用
local CurrentSchedule = nil
local V3OP
local DisplaySetType
local DormSecondEnter
local AttrType
local White = "#ffffff"
local Blue = "#34AFF8"

function XUiDormSecond:OnAwake()
    DisplaySetType = XDormConfig.VisitDisplaySetType
    DormSecondEnter = XDormConfig.DormSecondEnter
    AttrType = XFurnitureConfigs.AttrType
    V3OP = Vector3(-1, 1, 1)
    self.EnterBtns = {}
    XTool.InitUiObject(self)
    self:InitFun()
    self:InitUI()
    self:InitEnterCfg()
    self.PanelCaress.gameObject:SetActiveEx(false)
    self.LastMusicId = CS.XAudioManager.CurrentMusicId
    self.BgmShowState = false
    self.IsChangeOverView = true
    self.DormBgm = XUiDormBgm.New(self, self.MusicPlayer)
end

function XUiDormSecond:InitFun()
    self.OnBtnTaskTipsClickCb = function() self:OnBtnTaskTipsClick() end
    self.BtnClickTips.CallBack = function() self:ComfortTips() end
    self.BtnExpand.CallBack = function() self:OnBtnExpand() end
    self.BtnRename.CallBack = function() self:OpenRenameUI() end
    self:BindHelpBtn(self.BtnHelp, "Dorm", nil, XDormConfig.MarkDormCourseGuide)
    self.BtnDormTemplate.CallBack = function() self:OnBtnDormTemplateClick() end
    self.BtnNext.CallBack = function() self:OnBtnNextClick() end
    self.BtnCollect.CallBack = function() self:OnBtnCollectClick() end
    self.BtnDormShare.CallBack = function() self:OnBtnDormShareClick() end
end

function XUiDormSecond:OnBtnDormTemplateClick()
    --local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.CurDormId)
    --local connectId = roomData:GetConnectDormId()
    --local indexId = XDormConfig.GetDormTemplateSelecIndex(connectId)
    --XLuaUiManager.Open("UiDormTemplate", indexId, function()
    --    if XLuaUiManager.IsUiLoad("UiDormSecond") then
    --        self.IsChangeOverView = false
    --        self:Remove()
    --    end
    --end, self.CurDormId)
    XLuaUiManager.Open("UiDormDormitoryFormWork", nil, self.CurDormId)
end

function XUiDormSecond:OnBtnCollectClick()
    XLuaUiManager.Open("UiDormTemplateScene", self.CurDormId, XDormConfig.DormDataType.Target, self.CurDisplayState)
end

function XUiDormSecond:OnBtnDormShareClick()
    local dormDataType = XDormConfig.DormDataType.Self
    if self.CurDisplayState ~= DisplaySetType.MySelf then
        dormDataType = XDormConfig.DormDataType.Target
    end
    local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.CurDormId, dormDataType)

    local furnitureDatas = roomData:GetFurnitureDic()
    local furnitureList = {}

    for _, v in pairs(furnitureDatas) do
        local data = {
            ConfigId = v.ConfigId,
            X = v.GridX,
            Y = v.GridY,
            Angle = v.RotateAngle,
        }
        table.insert(furnitureList, data)
    end
    XDataCenter.DormManager.RequestDormSnapshotLayout(furnitureList, function(shareId)
        roomData:SetShareId(shareId)
        XHomeSceneManager.EnterShare(roomData)
    end)
end

function XUiDormSecond:OnDestroy()
    XDataCenter.DormManager.SetCurrentDormId(-1)
    if self.EventShow then
        self.EventShow:OnEventShowDestroy()
    end
    if XLuaUiManager.IsUiLoad("UiDormMain") and self.IsChangeOverView then
        XHomeSceneManager.ChangeBackToOverView()
    end

    if self.LastMusicId and self.LastMusicId > 0 then
        CS.XAudioManager.PlayMusic(self.LastMusicId)
    end
    if self.XUiDormSecondHead then
        self.XUiDormSecondHead:OnDestroy()
    end
    DisplaySetType = nil
    DormSecondEnter = nil
end

function XUiDormSecond:InitUI()
    self.CurScoreState = false
    self.CurInfoState = true
    self.TxtPerson.text = TextManager.GetText("DormPersonTxt")
    self.TxtRemould.text = TextManager.GetText("DormRemouldTxt")
    self.TxtMenu.text = TextManager.GetText("DormMenTxt")
    self.TxtScoreDes.text = TextManager.GetText("DormTotalScore")
    self.TxtTool.text = TextManager.GetText("DormComfortLevelTips")
    self.BtnRemould:SetName(TextManager.GetText("DormRemouldTxt"))
    self.BtnVisitor:ShowReddot(false)
    local a, b, c = XDataCenter.DormManager.GetDormitoryScoreNames()
    self.TxtBeautiful.text = a
    self.TxtComfort.text = b
    self.TxtPractical.text = c
    self:AddListener()
    self:InitList()

    local indexA = AttrType.AttrA
    local indexB = AttrType.AttrB
    local indexC = AttrType.AttrC
    local iconA = XFurnitureConfigs.GetDormFurnitureTypeIcon(indexA)
    local iconB = XFurnitureConfigs.GetDormFurnitureTypeIcon(indexB)
    local iconC = XFurnitureConfigs.GetDormFurnitureTypeIcon(indexC)
    self:SetUiSprite(self.ImgTool1, iconA)
    self:SetUiSprite(self.ImgTool2, iconB)
    self:SetUiSprite(self.ImgTool3, iconC)
end

function XUiDormSecond:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.ViewNameList.gameObject)
    self.DynamicTable:SetProxy(XUiDormNameGridItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiDormSecond:InitEnterCfg()
    self.EnterCfg = XDormConfig.GetSecondMenuList()
end

-- 跳到商店
function XUiDormSecond:OpenShopUI()
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm)
    self.IsStatic = true
end

-- 重置
function XUiDormSecond:OpenResetUI()
    XLuaUiManager.Open("UiDormReset", self.CurDormId, XDormConfig.DormDataType.Self)
end

-- 模板
function XUiDormSecond:OpenTemplateUI()
    XLuaUiManager.Open("UiDormDormitoryFormWork", nil, self.CurDormId)
end

-- [监听动态列表事件]
function XUiDormSecond:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.HostelNameDataList[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurIndex = index
        local d = self.HostelNameDataList[index]
        if self.CurDormId == d[2] then
            self.CurHostelNamesState = false
            self:SetDormListNameV(false)
            return
        end

        self.CurDormId = d[2]
        self:SetHostelNameClick()
        self:OnBtnHostelNamesClick()
        self:UpdateData(self.CurDisplayState, self.CurDormId)
        XHomeDormManager.CharacterExit(self.CurDormId)
        XHomeDormManager.SetSelectedRoom(self.CurDormId, true, self.CurDisplayState ~= XDormConfig.VisitDisplaySetType.MySelf)
    end
end

-- 可以访问宿舍lsit
function XUiDormSecond:SetCurHostelList()
    local len = 0
    local data = {}
    local dormdatas

    if DisplaySetType.MySelf == self.CurDisplayState then
        dormdatas = XDataCenter.DormManager.GetDormitoryData() or {}
    else
        dormdatas = XDataCenter.DormManager.GetDormitoryData(XDormConfig.DormDataType.Target) or {}
    end

    for _, v in pairs(dormdatas) do
        if v:WhetherRoomUnlock() then
            len = len + 1
            table.insert(data, { v:GetRoomName(), v:GetRoomId() })
        end
    end

    table.sort(data, function(a, b)
        local cfg1 = XDormConfig.GetDormitoryCfgById(a[2])
        local cfg2 = XDormConfig.GetDormitoryCfgById(b[2])
        return cfg1.InitNumber < cfg2.InitNumber
    end)
    self.HostelNameDataList = data
    self.DynamicTable:Clear()
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync(1)
    self.ImgDownUp.gameObject:SetActiveEx(len > 1)
    self.ImgArrowDown.gameObject:SetActiveEx(len > 1)
    self.ImgArrowUp.gameObject:SetActiveEx(len < 1)
end

-- 设置模板宿舍
function XUiDormSecond:SetTemplateInfo()
    local dormDataType = XDormConfig.DormDataType.Self
    if self.CurDisplayState ~= DisplaySetType.MySelf then
        dormDataType = XDormConfig.DormDataType.Target
    end
    local roomData = XDataCenter.DormManager.GetRoomDataByRoomId(self.CurDormId, dormDataType)
    local connectId = roomData:GetConnectDormId()
    local isConect = connectId > 0
    self.BtnDormTemplate.gameObject:SetActiveEx(self.CurDisplayState == DisplaySetType.MySelf)
    self.BtnDormShare.gameObject:SetActiveEx(true)

    if not isConect then
        self.SliderTemplate.fillAmount = 0
        return
    end

    local prrcent = XDataCenter.DormManager.GetDormTemplatePercent(self.CurDormId, connectId)
    self.SliderTemplate.fillAmount = prrcent / 100
end

-- 设置当前宿舍名(ClickOrInit)
function XUiDormSecond:SetHostelNameClick()
    local dormdatas
    if DisplaySetType.MySelf == self.CurDisplayState then
        dormdatas = XDataCenter.DormManager.GetDormitoryData() or {}
    else
        dormdatas = XDataCenter.DormManager.GetDormitoryData(XDormConfig.DormDataType.Target) or {}
    end

    local d = dormdatas[self.CurDormId]
    if not d then
        return
    end
    local name = d:GetRoomName() or ""
    self.TxtTitle.text = name
end

-- 设置当前宿舍名(改名成功)
function XUiDormSecond:SetHostelName(name)
    self.TxtTitle.text = name or ""
    self:SetCurHostelList()
end

-- 设置宿舍list显示与隐藏
function XUiDormSecond:SetDormListNameV(state)
    self.ListContent.gameObject:SetActiveEx(state)
    self.ImgArrowUp.gameObject:SetActiveEx(state)
    self.ImgArrowDown.gameObject:SetActiveEx(not state)
end


function XUiDormSecond:SetSelectState(state)
    if not self.PanelSelect then
        return
    end

    self.PanelSelect.gameObject:SetActiveEx(state)
end

function XUiDormSecond:CreateDormMainItems()
end

-- 人员
function XUiDormSecond:OnBtnPersonClick()
    local cfg = XDormConfig.GetDormitoryCfgById(self.CurDormId)
    local sceneId = cfg and cfg.SceneId
    XLuaUiManager.Open("UiDormPerson", sceneId) --要传入宿舍场景ID
end

-- 任务
function XUiDormSecond:OpenTaskUI()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    XLuaUiManager.Open("UiDormTask")
end

-- 建造
function XUiDormSecond:OpenBuildUI()
    if XDataCenter.FurnitureManager.CheckFurnitureSlopLimit() then
        XLuaUiManager.Open("UiFurnitureCreateDetail")
        return
    end
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    XLuaUiManager.Open("UiFurnitureBuild")
end

-- 说明
function XUiDormSecond:OpenDesUI()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    XUiManager.UiFubenDialogTip("", CS.XTextManager.GetText("DormDesSecond") or "")
end

-- 仓库
function XUiDormSecond:OpenWarehouse()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    XLuaUiManager.Open("UiDormBag", nil, nil, nil, nil, nil, nil, true)
end

-- 改名
function XUiDormSecond:OpenRenameUI()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    if not self.RenameInit then
        self.RenameInit = true
        self.PanelRenameUI = XUiDormReName.New(self.PanelRename, self)
    end
    self.PanelRename.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelRenameEnable")
    self.PanelRenameUI:OnRefresh(self.CurDormId)
end

function XUiDormSecond:InitEventShow()
    if not self.EventShow then
        self.EventShow = XUiPanelEventShow.New(self, self.PanelEventShow)
    end
end

function XUiDormSecond:InitHead()
    if not self.XUiDormSecondHead then
        self.XUiDormSecondHead = XUiDormSecondHead.New(self, self.PanelHead)
        self.XUiDormSecondHead:Init()
    end
end

-- 访问
function XUiDormSecond:OnBtnVistorClick()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    self.GameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiDormVisit", self)
end

-- 图鉴
function XUiDormSecond:OpenFieldGuid()
    self.CurMenState = false
    self:SetEnterState(self.CurMenState)
    XLuaUiManager.Open("UiDormFieldGuide")
end

-- 设置评分
function XUiDormSecond:SetScore()
    local scoreA, scoreB, scoreC
    if DisplaySetType.MySelf == self.CurDisplayState then
        scoreA, scoreB, scoreC = XDataCenter.DormManager.GetDormitoryScore(self.CurDormId)
    else
        scoreA, scoreB, scoreC = XDataCenter.DormManager.GetDormitoryScore(self.CurDormId, XDormConfig.DormDataType.Target)
    end

    local indexA = AttrType.AttrA
    local indexB = AttrType.AttrB
    local indexC = AttrType.AttrC
    local a = XFurnitureConfigs.GetFurnitureAttrLevelNewDescription(1, indexA, scoreA)
    local b = XFurnitureConfigs.GetFurnitureAttrLevelNewDescription(1, indexB, scoreB)
    local c = XFurnitureConfigs.GetFurnitureAttrLevelNewDescription(1, indexC, scoreC)
    local totalScore = 0
    if DisplaySetType.MySelf == self.CurDisplayState then
        local newFurnitureAttrs = XHomeDormManager.GetFurnitureScoresByRoomId(self.CurDormId)
        totalScore = newFurnitureAttrs.TotalScore
    else
        local newFurnitureAttrs = XDataCenter.DormManager.GetDormitoryTargetScore(self.CurDormId)
        if newFurnitureAttrs then
            totalScore = newFurnitureAttrs.TotalScore
        end
    end
    self.TxtScore.text = XFurnitureConfigs.GetFurnitureTotalAttrLevelNewColorDescription(1, totalScore)
    self.TxtBeautifulNum.text = a
    self.TxtComfortNum.text = b
    self.TxtPracticalNum.text = c
end

function XUiDormSecond:SetVisitState()
    if DisplaySetType.MySelf == self.CurDisplayState then
        self.PanelHomeSelf.gameObject:SetActiveEx(true)
        self.PanelHomeOthers.gameObject:SetActiveEx(false)
        self.BtnMenu.gameObject:SetActiveEx(true)
        --self.BtnVisitor.gameObject:SetActiveEx(true)
        self.BtnAdd.gameObject:SetActiveEx(false)
        self.BtnRemould.gameObject:SetActiveEx(true)
        self.DormRename.gameObject:SetActiveEx(true)
        return
    end

    self.PanelHomeSelf.gameObject:SetActiveEx(false)
    self.PanelHomeOthers.gameObject:SetActiveEx(true)
    self.BtnRemould.gameObject:SetActiveEx(false)
    self.BtnVisitor.gameObject:SetActiveEx(false)
    self.BtnMenu.gameObject:SetActiveEx(false)
    self.DormRename.gameObject:SetActiveEx(false)
    if DisplaySetType.MyFriend == self.CurDisplayState then
        self.BtnAdd.gameObject:SetActiveEx(false)
    else
        self.BtnAdd.gameObject:SetActiveEx(true)
    end
end

function XUiDormSecond:OnStart(displaytype, dormId, playerId)
    self:InitHead()
    self:UpdateData(displaytype, dormId)
    self:InitEventShow()
    self.IsStatic = false
    self.CurPlayerId = playerId
    self.PanelBtn.gameObject:SetActiveEx(false)
end

function XUiDormSecond:GetCurIndex(dormId)
    if self.HostelNameDataList then
        for index, v in pairs(self.HostelNameDataList) do
            if v[2] == dormId then
                return index
            end
        end
    end
    return 1
end

function XUiDormSecond:UpdateData(displaytype, dormId, playerId)
    self.CurDisplayState = displaytype
    self.CurDormId = dormId
    XDataCenter.DormManager.SetCurrentDormId(self.CurDormId)
    self.CurPlayerId = playerId
    self:SetScore()
    self:SetVisitState()
    self:SetHostelNameClick()
    self:SetCurHostelList()
    self:SetTemplateInfo()

    self.XUiDormSecondHead:Refresh(self.CurDormId)
    self:ShowPanelHead(true)

    self.CurIndex = self:GetCurIndex(dormId)

    if DisplaySetType.MySelf ~= self.CurDisplayState then
        self.BgmShowState = false
        self.MusicPlayer.gameObject:SetActiveEx(self.BgmShowState)
    end

    self.DormBgm:UpdateBgmList(dormId, self.CurDisplayState == DisplaySetType.MySelf)
end

function XUiDormSecond:SkipDormUpdateData(dormId)
    self:UpdateData(DisplaySetType.MySelf, dormId)
end

function XUiDormSecond:OnRecordSelfDormId()
    SelfPreDormId = self.CurDormId
end

function XUiDormSecond:OnEnable()
    self.BtnPanelTask.CallBack = self.OnBtnTaskTipsClickCb
    self:SetScore()
    XDataCenter.DormManager.GetNextShowEvent()
    self:OnPlayAnimation()
    XDataCenter.DormManager.StartDormRedTimer()

    local types = XRedPointConditions.Types
    XRedPointManager.AddRedPointEvent(self.BtnTask.ReddotObj, self.RefreshTaskTabRedDot, self, { types.CONDITION_DORM_MAIN_TASK_RED })
    XRedPointManager.AddRedPointEvent(self.BtnMenu.ReddotObj, self.OnCheckBuildFurniture, self, { types.CONDITION_FURNITURE_CREATE })

    self:RefreshTaskInfo()
    self.SkipFun = self.SkipDormUpdateData
    XEventManager.AddEventListener(XEventId.EVENT_DORM_SKIP, self.SkipFun, self)
    XEventManager.AddEventListener(XEventId.EVENT_CARESS_SHOW, self.OnCaressShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_HIDE, self.OnCaressHide, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_ENTER, self.OnOpenedCaress, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_SHOW_EVENT_CHANGE, self.OnOpenEventShow, self)
    self.DormBgm:ResetBgmList(self.CurDormId, DisplaySetType.MySelf == self.CurDisplayState)
    self:SetTemplateInfo()
    self:PlayAnimation("MusicPlayerQieHuan")
end

function XUiDormSecond:OnCaressHide()
    if self.CurInfoState then
        self:BtnHideCb()
    else
        self:BtnScreenShotCb()
    end
end

function XUiDormSecond:RefreshTaskTabRedDot(count)
    self.BtnTask:ShowReddot(count >= 0)
    self:RefreshTaskInfo()
end

function XUiDormSecond:RefreshTaskInfo()
    local data, tasktype, state = XDataCenter.TaskManager.GetDormTaskTips()
    if data and tasktype and state then
        self.CurTaskData = data
        self.TaskType = tasktype
        local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
        self.CurTaskTagState = state == XDataCenter.TaskManager.TaskState.Achieved
        if self.CurTaskTagState then
            self.BtnPanelTask:SetName(string.format("<color=%s>%s</color>", Blue, config.Desc))
        else
            self.BtnPanelTask:SetName(string.format("<color=%s>%s</color>", White, config.Desc))
        end
        self.BtnPanelTask:ShowTag(not self.CurTaskTagState)
        self.BtnPanelTask:ShowReddot(self.CurTaskTagState)
    else
        self.CurTaskData = nil
        self.PanelTask.gameObject:SetActiveEx(false)
    end
end

function XUiDormSecond:PlayBgmMusic(show, bgmConfig)
    self.BgmShowState = show

    if DisplaySetType.MySelf ~= self.CurDisplayState then
        self.BgmShowState = false
    else
        CS.UnityEngine.PlayerPrefs.SetInt(tostring(self.CurDormId), bgmConfig.BgmId)
    end

    self:PlayAnimation("MusicPlayerQieHuan")
    self.MusicPlayer.gameObject:SetActiveEx(self.BgmShowState)
    CS.XAudioManager.PlayMusic(bgmConfig.BgmId)

    XHomeDormManager.DormBgm[self.CurDormId] = bgmConfig
end


function XUiDormSecond:OnCheckBuildFurniture(count)
    local red = count >= 0
    self.BtnMenu:ShowReddot(red)
    if self.EnterBtns[DormSecondEnter.Build] then
        self.EnterBtns[DormSecondEnter.Build]:ShowReddot(red)
    end
end

function XUiDormSecond:OnDisable()
    self.BtnPanelTask.CallBack = nil
    XDataCenter.DormManager.StopDormRedTimer()
    self.CurHostelNamesState = false
    self:SetDormListNameV(self.CurHostelNamesState)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_SKIP, self.SkipFun, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CARESS_SHOW, self.OnCaressShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_TOUCH_HIDE, self.OnCaressHide, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_TOUCH_ENTER, self.OnOpenedCaress, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_SHOW_EVENT_CHANGE, self.OnOpenEventShow, self)
    self.DormBgm:OnDisable()

end

function XUiDormSecond:OnCaressShow()
    self.BtnScreenShot.gameObject:SetActiveEx(true)
    self.BtnHide.gameObject:SetActiveEx(false)
end

-- 爱抚(打开)
function XUiDormSecond:OnOpenedCaress(characterId)
    self.PanelHostelName.gameObject:SetActiveEx(false)
    self.PanelCaress.gameObject:SetActiveEx(true)
    self.BtnRemould.gameObject:SetActiveEx(false)
    self.BtnVisitor.gameObject:SetActiveEx(false)
    self.PanelMenu.gameObject:SetActiveEx(false)
    self.BtnTask.gameObject:SetActiveEx(false)
    self.BtnRename.gameObject:SetActiveEx(false)
    self.BtnBack.gameObject:SetActiveEx(false)
    self.DormBgm.GameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.TopInfos.gameObject:SetActiveEx(false)
    self.BtnCollect.gameObject:SetActiveEx(false)
    self.BtnDormShare.gameObject:SetActiveEx(false)
    self.BtnDormTemplate.gameObject:SetActiveEx(false)
    self.BtnEdit.gameObject:SetActiveEx(false)

    if not self.InitCaress then
        self.InitCaress = true
        self.PanelCaressUI = XUiDormCaress.New(self, self.PanelCaress)
    end
    self:PlayAnimation("PanelCaressEnable")
    self.PanelCaressUI:Show(characterId, self.CurDormId)
end

-- 爱抚(关闭)
function XUiDormSecond:OnCloseedCaress()
    self:PlayAnimation("PanelCaressDisable", function()
        self.PanelCaressDisable.extrapolationMode = 2
    end)
    self.PanelHostelName.gameObject:SetActiveEx(true)
    self.PanelCaress.gameObject:SetActiveEx(false)
    self.BtnRemould.gameObject:SetActiveEx(true)
    --self.BtnVisitor.gameObject:SetActiveEx(true)
    self.PanelMenu.gameObject:SetActiveEx(true)
    self.BtnTask.gameObject:SetActiveEx(true)
    self.BtnRename.gameObject:SetActiveEx(true)
    self.BtnBack.gameObject:SetActiveEx(true)
    self.DormBgm.GameObject:SetActiveEx(true)
    self.BtnHelp.gameObject:SetActiveEx(true)
    self.TopInfos.gameObject:SetActiveEx(true)
    self.BtnCollect.gameObject:SetActiveEx(true)
    self.BtnDormShare.gameObject:SetActiveEx(true)
    self.BtnDormTemplate.gameObject:SetActiveEx(true)
    self.BtnEdit.gameObject:SetActiveEx(true)
    self.PanelCaressUI:OnClose(self.CurDormId)
end

function XUiDormSecond:OnOpenEventShow(data)
    self.EventShow:Show(data)
end

function XUiDormSecond:OnBtnTaskTipsClick()
    if self.CurTaskData and not self.CurTaskTagState then
        self:OnTaskSkip()
        return
    end

    local tab
    if self.CurTaskTagState then
        if self.TaskType == XDataCenter.TaskManager.TaskType.DormNormal then
            tab = XTaskConfig.PANELINDEX.Story
        else
            tab = XTaskConfig.PANELINDEX.Daily
        end
    end
    self:OnOpenTask(tab)
end

function XUiDormSecond:OnOpenTask(tab)
    XLuaUiManager.Open("UiDormTask", tab)
    self.IsStatic = true
end

function XUiDormSecond:OnBtnTaskClick()
    self:OnOpenTask()
end

function XUiDormSecond:OnBtnEditClick()
    if self.CurDisplayState == XDormConfig.DormDataType.Template 
            or self.CurDisplayState == XDormConfig.DormDataType.Collect 
            or self.CurDisplayState == XDormConfig.DormDataType.Provisional 
            or self.CurDisplayState == XDormConfig.DormDataType.CollectNone then
        return
    end
    local config = XDormConfig.GetDormitoryCfgById(self.CurDormId)
    XLuaUiManager.Open("UiDormPerson", XDormConfig.PersonType.Staff, config.SceneId, self.CurDormId)
end

function XUiDormSecond:OnTaskSkip()
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.RunMain()
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.CurTaskData.Id).SkipId
            XFunctionManager.SkipInterface(skipId)
        end)
    else
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.CurTaskData.Id).SkipId
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiDormSecond:AddListener()
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUIClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClick)
    self:RegisterClickEvent(self.BtnMenu, self.OnBtnMenuClick)
    self:RegisterClickEvent(self.BtnVisitor, self.OnBtnVistorClick)
    self:RegisterClickEvent(self.BtnClick, self.OnBtnHostelNamesClick)
    self:RegisterClickEvent(self.BtnSkipClick, self.OnBtnMenuHide)
    self:RegisterClickEvent(self.BtnRemould, self.OnBtnRemouldClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self.BtnScreenShot.CallBack = function() self:BtnScreenShotCb() end
    self.BtnHide.CallBack = function() self:BtnHideCb() end
    self.BtnExpandNormalTran = self.BtnExpand.NormalObj.transform
    self.BtnEdit.CallBack = function() self:OnBtnEditClick() end
end

function XUiDormSecond:BtnHideCb()
    self.BtnHide.gameObject:SetActiveEx(false)
    self.BtnScreenShot.gameObject:SetActiveEx(true)
    self.MusicPlayer.gameObject:SetActiveEx(self.BgmShowState)
    if self.PanelCaress.gameObject.activeSelf then
        self.PanelCaressUI.BtnBack.gameObject:SetActiveEx(true)
        self:PlayAnimation("CaressBtnEnable", function()
            if DisplaySetType.MySelf == self.CurDisplayState then
                self.PanelHomeSelf.gameObject:SetActiveEx(true)
                self.PanelHomeOthers.gameObject:SetActiveEx(false)
            else
                self.PanelHomeSelf.gameObject:SetActiveEx(false)
                self.PanelHomeOthers.gameObject:SetActiveEx(true)
            end
            
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_EXP_SHOW)
        end)
    else
        self:PlayAnimation("BtnEnable", function()
            if DisplaySetType.MySelf == self.CurDisplayState then
                self.PanelHomeSelf.gameObject:SetActiveEx(true)
                self.PanelHomeOthers.gameObject:SetActiveEx(false)
                self.BtnRename.gameObject:SetActiveEx(true)
            else
                self.PanelHomeSelf.gameObject:SetActiveEx(false)
                self.PanelHomeOthers.gameObject:SetActiveEx(true)
                self.BtnRename.gameObject:SetActiveEx(false)
            end
            self.CurInfoState = true
            self.BtnHelp.gameObject:SetActiveEx(true)
            self.BtnBack.gameObject:SetActiveEx(true)
            self.TopInfos.gameObject:SetActiveEx(true)
            self.PanelHostelName.gameObject:SetActiveEx(true)
            self:ShowPanelHead(true)

            XEventManager.DispatchEvent(XEventId.EVENT_DORM_SECOND_STATE, true)
        end)
    end
end

function XUiDormSecond:BtnScreenShotCb()
    self.BtnHide.gameObject:SetActiveEx(true)
    self.BtnScreenShot.gameObject:SetActiveEx(false)
    if self.PanelCaress.gameObject.activeSelf then
        self.PanelCaressUI.BtnBack.gameObject:SetActiveEx(false)
        self:PlayAnimation("CaressBtnDisable", function()
            self.PanelHomeSelf.gameObject:SetActiveEx(false)
            self.PanelHomeOthers.gameObject:SetActiveEx(false)
            self.BtnBack.gameObject:SetActiveEx(false)
            self.BtnHelp.gameObject:SetActiveEx(false)
            self.BtnRename.gameObject:SetActiveEx(false)
            self.PanelHostelName.gameObject:SetActiveEx(false)
            self.TopInfos.gameObject:SetActiveEx(false)
            self.MusicPlayer.gameObject:SetActiveEx(false)

            XEventManager.DispatchEvent(XEventId.EVENT_DORM_EXP_HIDE)
        end)
    else
        self:PlayAnimation("BtnDisable", function()
            self.PanelHomeSelf.gameObject:SetActiveEx(false)
            self.PanelHomeOthers.gameObject:SetActiveEx(false)
            self.BtnBack.gameObject:SetActiveEx(false)
            self.BtnHelp.gameObject:SetActiveEx(false)
            self.BtnRename.gameObject:SetActiveEx(false)
            self.PanelHostelName.gameObject:SetActiveEx(false)
            self.TopInfos.gameObject:SetActiveEx(false)
            self.MusicPlayer.gameObject:SetActiveEx(false)
            self.CurInfoState = false

            self:ShowPanelHead(false)
        end)
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_SECOND_STATE, false)
    end
end

function XUiDormSecond:OnBtnExpand()
    self.CurScoreState = not self.CurScoreState
    self.PanelScore.gameObject:SetActiveEx(self.CurScoreState)
    self.PanelTool1.gameObject:SetActiveEx(not self.CurScoreState)
    self.PanelTool2.gameObject:SetActiveEx(not self.CurScoreState)
    self.PanelTool3.gameObject:SetActiveEx(not self.CurScoreState)
    if self.CurScoreState then
        self.BtnExpandNormalTran.localScale = V3OP
        self.BtnClickTips.gameObject:SetActiveEx(false)
    else
        self.BtnExpandNormalTran.localScale = V3O
        self.BtnClickTips.gameObject:SetActiveEx(true)
    end
end

function XUiDormSecond:ComfortTips()
    if not CurrentSchedule then
        self.TopTips.gameObject:SetActiveEx(true)
        CurrentSchedule = XScheduleManager.ScheduleForever(function() self:ComfortTipsTimerCb() end, XDormConfig.DormComfortTime)
    end
end

function XUiDormSecond:ComfortTipsTimerCb()
    if not XTool.UObjIsNil(self.TopTips) then
        self.TopTips.gameObject:SetActiveEx(false)
    end
    XScheduleManager.UnSchedule(CurrentSchedule)
    CurrentSchedule = nil
end

function XUiDormSecond:OnBtnMenuHide()
    if self.HostSecondSkipGo and self.CurMenState == true then
        self.CurMenState = false
        self:SetEnterState(self.CurMenState)
    end
end

function XUiDormSecond:OnBtnRightClick()
    if self.HostelNameDataList and #self.HostelNameDataList <= 1 then
        XUiManager.TipText("DormNoRoomsTips")
        return
    end

    local d = self.HostelNameDataList[self.CurIndex + 1]
    if not d then
        --到末了，从头开始
        self.CurIndex = 1
        d = self.HostelNameDataList[self.CurIndex]
        self:UpdateData(self.CurDisplayState, d[2])
        XHomeDormManager.CharacterExit(self.CurDormId)
        XHomeDormManager.SetSelectedRoom(self.CurDormId, true)
        return
    end

    if self.CurDormId == d[2] then
        return
    end

    self.CurIndex = self.CurIndex + 1
    self:UpdateData(self.CurDisplayState, d[2])
    XHomeDormManager.CharacterExit(self.CurDormId)
    XHomeDormManager.SetSelectedRoom(self.CurDormId, true)
end

function XUiDormSecond:OnBtnLeftClick()
    if self.HostelNameDataList and #self.HostelNameDataList <= 1 then
        XUiManager.TipText("DormNoRoomsTips")
        return
    end

    local d = self.HostelNameDataList[self.CurIndex - 1]
    if not d then
        --到末了，从头开始
        self.CurIndex = #self.HostelNameDataList
        d = self.HostelNameDataList[self.CurIndex]
        self:UpdateData(self.CurDisplayState, d[2])
        XHomeDormManager.CharacterExit(self.CurDormId)
        XHomeDormManager.SetSelectedRoom(self.CurDormId, true)
        return
    end

    if self.CurDormId == d[2] then
        return
    end

    self.CurIndex = self.CurIndex - 1
    self:UpdateData(self.CurDisplayState, d[2])
    XHomeDormManager.CharacterExit(self.CurDormId)
    XHomeDormManager.SetSelectedRoom(self.CurDormId, true)
end

function XUiDormSecond:OnBtnNextClick()
    if self.CurNextState then
        local nextDormId, flag = XDataCenter.DormManager.GetDormitoryRecommendDataForNext(self.CurDormId)
        self.CurNextState = not flag
        self:UpdateData(DisplaySetType.Stranger, nextDormId)
        return
    end

    local preDormId, flag = XDataCenter.DormManager.GetDormitoryRecommendDataForPre(self.CurDormId)
    self.CurNextState = flag
    self:UpdateData(DisplaySetType.Stranger, preDormId)
end

function XUiDormSecond:OnBtnAddClick()
    local data = XDataCenter.DormManager.GetDormitoryData(XDormConfig.DormDataType.Target)

    if not data then
        return
    end

    local dormdata = data[self.CurDormId]
    local title = CS.XTextManager.GetText("TipTitle")
    local des = CS.XTextManager.GetText("DormVisitorFirend", dormdata.PlayerName)
    XUiManager.DialogTip(title, des, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.SocialManager.ApplyFriend(dormdata.PlayerId)
    end)
end

function XUiDormSecond:OnBtnHostelNamesClick()
    if self.HostelNameDataList and #self.HostelNameDataList <= 1 then
        return
    end

    self.CurHostelNamesState = not self.CurHostelNamesState
    self:SetDormListNameV(self.CurHostelNamesState)
end

function XUiDormSecond:OnBtnRemouldClick()
    XLuaUiManager.Open("UiFurnitureReform", self.CurDormId, XDormConfig.DormDataType.Self)
end

function XUiDormSecond:OnBtnMainUIClick()
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_CLOSE_COMPONET)

    XLuaUiManager.RunMain()
    XHomeSceneManager.LeaveScene()
end

function XUiDormSecond:PcClose()
    if self.PanelRename.gameObject.activeSelf then
        self.PanelRename.gameObject:SetActiveEx(false)
        return
    end
    self:OnBtnReturnClick()
end

function XUiDormSecond:OnBtnReturnClick()
    if not XLuaUiManager.IsUiLoad("UiDormMain") then
        XHomeSceneManager.LeaveScene()
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_CLOSE_COMPONET)
        self:Close()
        return
    end

    if self.CurDisplayState == DisplaySetType.MySelf then
        XHomeDormManager.SetSelectedRoom(self.CurDormId, false)
        self:Close()
    else
        --从其他人宿舍返回自己宿舍，把自己的数据切回来。
        if SelfPreDormId == -1 then --从主界面访问 -> 返回
            --local data = XDataCenter.DormManager.GetDormitoryData(XDormConfig.DormDataType.Self)
            --if data then
            --    for _, v in pairs(data) do
            --        if v and v.Id then
            --            SelfPreDormId = v.Id
            --            break
            --        end
            --    end
            --end
            XDataCenter.DormManager.BackToDormitoryMain(self.CurDormId)
            self:Close()
        else
            XDataCenter.DormManager.VisitDormitory(DisplaySetType.MySelf, SelfPreDormId)
            self:UpdateData(DisplaySetType.MySelf, SelfPreDormId)
            self.CurHostelNamesState = false
            self:SetDormListNameV(self.CurHostelNamesState)
        end
    end
    SelfPreDormId = -1
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_HIDE_COMPONENT)
end

function XUiDormSecond:OnBtnMenuClick()
    if self.HostSecondSkipGo then
        self.CurMenState = not self.CurMenState
        self:SetEnterState(self.CurMenState)
    end
end

function XUiDormSecond:SetEnterState(state)
    if self.HostSecondSkipGo then
        self.HostSecondSkipGo.gameObject:SetActiveEx(state)
        if state then
            self:PlayAnimation("CaiDanEnable")
        else
            self:PlayAnimation("CaiDanDisable")
        end
        if not state or self.InitEnter then
            return
        end
        self.InitEnter = true
        for id, template in ipairs(self.EnterCfg) do
            local obj = Object.Instantiate(self.HostSecondSkipItem.gameObject, self.HostSecondSkipList, false)
            obj.transform.localScale = V3O
            obj.gameObject:SetActiveEx(true)
            local btn = obj:GetComponent("XUiButton")
            btn:SetName(template.Name)
            btn:SetSprite(template.IconPath)
            self:RegisterClickEvent(obj, handler(self, self[template.FunctionName]))
            self.EnterBtns[id] = btn
        end
    end
end

function XUiDormSecond:OnPlayAnimation()
    local delay = 0
    if not self.IsStatic then
        self.IsStatic = true
        delay = XDormConfig.DormSecondAnimationDelayTime
    end

    if delay > 0 then
        self.DormWorkTimer = XScheduleManager.ScheduleOnce(function()
            self.PanelBtn.gameObject:SetActiveEx(true)
            self:PlayAnimation("AnimStartEnable")
            XScheduleManager.UnSchedule(self.DormWorkTimer)
        end, delay)
    else
        self:PlayAnimation("AnimStartEnable")
    end
end

function XUiDormSecond:ShowPanelHead(isShow)
    --如果不是进入自己的宿舍不显示
    if DisplaySetType.MySelf ~= self.CurDisplayState then
        self.PanelHead.gameObject:SetActiveEx(false)
    else
        self.PanelHead.gameObject:SetActiveEx(isShow)
    end
end