local XUiPanelTheatre4Model = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4Model")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
local XUiPanelTheatre4TimeLine = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4TimeLine")
local XUiPanelTheatre4EventTip = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4EventTip")
local XUiPanelTheatre4GameStartCard = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4GameStartCard")
local XUiPanelTheatre4GameBuildingCard = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4GameBuildingCard")
local XUiPanelTheatre4PropInfo = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4PropInfo")
local XUiPanelTheatre4BossInfo = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4BossInfo")
local XUiTheatre4RollingNumber = require("XUi/XUiTheatre4/Common/XUiTheatre4RollingNumber")
local XUiPanelTheatre4BackSelect = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4BackSelect")
---@class XUiTheatre4Game : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Game = XLuaUiManager.Register(XLuaUi, "UiTheatre4Game")
local CSVector2 = CS.UnityEngine.Vector2

function XUiTheatre4Game:OnAwake()
    self.PanelWakeUp = self.PanelWakeUp or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/PanelColour/PanelResources/PanelWakeUp")
    self.TxtWakeUpNum = self.TxtWakeUpNum or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/PanelColour/PanelResources/PanelWakeUp/TxtWakeUpNum", "Text")

    self.BtnClose.gameObject:SetActiveEx(false)
    self.PanelEvent.gameObject:SetActiveEx(false)
    self.EffectScreen.gameObject:SetActiveEx(false)
    --self.EffectSnow.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)
    self.EffectBossTips.gameObject:SetActiveEx(false)
    self.Mask.gameObject:SetActiveEx(false)
    self.PanelBack.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitModel()
    self:InitColour()
    self:InitInfo()
    -- 是否第一次打开
    self.IsFirstOpen = true
    -- 是否播放启用动画
    self.IsPlayEnableAnim = false
    -- 当前繁荣度
    self.CurProsperity = 0
    ---@type XUiTheatre4RollingNumber
    self.ProsperityNumber = false
    ---@type XUiPanelTheatre4EventTip[]
    self._GridFates = {}
end

function XUiTheatre4Game:InitModel()
    ---@type XUiPanelTheatre4Model
    self.PanelModel = XUiPanelTheatre4Model.New(self.UiModelGo, self)
    self.PanelModel:Open()
end

function XUiTheatre4Game:InitColour()
    ---@type XUiTheatre4ColorResource
    self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self, handler(self, self.OnColourClick), false, true)
    self.PanelColour:Open()
end

function XUiTheatre4Game:InitInfo()
    ---@type XUiPanelTheatre4BossInfo
    self.BossInfo = XUiPanelTheatre4BossInfo.New(self.PanelBoss, self)
    ---@type XUiPanelTheatre4PropInfo
    self.PropInfo = XUiPanelTheatre4PropInfo.New(self.PanelProp, self)
    self.BossInfo:Open()
    self.PropInfo:Open()
end

-- 检查是否需要播放新区域动画
function XUiTheatre4Game:CheckNeedPlayNewAreaAnim()
    -- 新开的一局和有到达新区域 进入时不刷新地图格子 等播放完新区域动画再刷新
    if self._Control:CheckIsNewAdventure() or self._Control:CheckHasArriveNewAreaPopup() then
        return true
    end
    return false
end

function XUiTheatre4Game:OnStart()
    -- 生成地图
    self.PanelModel:GenerateAllMapGroup()
    -- 当前地图Id
    local curMapId = self._Control.MapSubControl:GetCurrentMapId()
    local cueTag = self._Control.MapSubControl:GetMapCueTag(curMapId)
    -- 播放黑屏动画
    self.IsPlayEnableAnim = true
    self.Mask.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("GameEnable", function()
        self.Mask.gameObject:SetActiveEx(false)
        -- 显示雪的特效
        self:ShowSnowEffect()
        if not self:CheckNeedPlayNewAreaAnim() then
            -- 刷新当前地图的格子
            self.PanelModel:RefreshMap(curMapId)
            XLuaAudioManager.SetWholeSelector("MusicSwitch", cueTag)
            local cueId = self._Control:GetClientConfig("SwitchFloorCueId", 1, true)
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
        end
        -- 新开的冒险不播放进入动画
        if not self._Control:CheckIsNewAdventure() then
            self:PlayInAnim()
        end
        self:HandleForcePlayEventAndPopup()
        self.IsPlayEnableAnim = false
    end)
    -- 播放退出动画
    self:PlayOutAnim()
    if not self:CheckNeedPlayNewAreaAnim() then
        -- 隐藏云雾
        self.PanelModel:HideCloudEffect(curMapId)
    end

    local isSkipSettlement = self._Control.SystemControl:GetIsSkipSettlement()
    self.BtnSkip:SetButtonState(isSkipSettlement and CS.UiButtonState.Select or CS.UiButtonState.Normal)

    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_RESTRICT_FOCUS, self.AfterSelectFightReward, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_TIME_BACK, self.PlayTimeBackAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_REFRESH_TIME_LINE, self.RefreshTimeLine, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_PLAY_SCREEN_EFFECT, self.PlayScreenEffect, self)
end

function XUiTheatre4Game:OnEnable()
    self:RefreshInfo()
    self:RefreshBuildPoint()
    self:RefreshProsperity()
    self:RefreshWakeUpPoint()
    self:RefreshTimeLine()
    self:RefreshNextBtn()
    self:RefreshTimeBack()
    self:ShowStarDownTip()
    self:CheckFateShowEventTip()
    self:SetCameraPositionAndDistance()
    if not self.IsPlayEnableAnim then
        self:PlayInAnim(true)
        self:HandleForcePlayEventAndPopup()
    end
    if self.IsFirstOpen then
        self.IsFirstOpen = false
    end


end

function XUiTheatre4Game:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA,
        XEventId.EVENT_THEATRE4_UPDATE_MAP_GRID_DATA,
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
        XEventId.EVENT_THEATRE4_UPDATE_FATE_DATA,
        XEventId.EVENT_THEATRE4_ADD_CHAPTER,
        XEventId.EVENT_THEATRE4_BUILD_START,
        XEventId.EVENT_THEATRE4_BUILD_SELECT_GRID,
        XEventId.EVENT_THEATRE4_BUILD_END,
        XEventId.EVENT_THEATRE4_OPEN_BUILDING_DETAIL,
        XEventId.EVENT_THEATRE4_CLOSE_BUILDING_DETAIL,
        XEventId.EVENT_THEATRE4_FOCUS_GRID,
        XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_OUT,
        XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_IN,
        XEventId.EVENT_THEATRE4_SAVE_CAMERA_POS,
        XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS,
    }
end

function XUiTheatre4Game:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_THEATRE4_UPDATE_ADVENTURE_DATA then
        self.PanelModel:RefreshAllMap()
        self.BossInfo:RefreshCurrentTimeInfo()
    elseif event == XEventId.EVENT_THEATRE4_UPDATE_MAP_GRID_DATA then
        self.PanelModel:RefreshMap(args[1])
        self.BossInfo:RefreshBoss()
        self:PlayLeftBossEffect()
        self:ShowStarDownTip()
    elseif event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshBuildPoint()
        self:RefreshProsperity(true)
        self:RefreshWakeUpPoint()
        self:RefreshNextBtn()
        self.BossInfo:RefreshCurrentProsperity()
        self:RefreshTimeBack()
    elseif event == XEventId.EVENT_THEATRE4_UPDATE_FATE_DATA then
        self:CheckFateShowEventTip()
        self:RefreshTimeLine()
    elseif event == XEventId.EVENT_THEATRE4_ADD_CHAPTER then
        local lastChapterData = self._Control.MapSubControl:GetLastChapterData()
        self.PanelModel:GenerateMapGroup(lastChapterData, lastChapterData:GetMapId())
        self.BossInfo:RefreshBoss()
        self:PlayLeftBossEffect()
    elseif event == XEventId.EVENT_THEATRE4_BUILD_START then
        local curMapId = args[1]
        local optionalGridIds = args[2]
        self.PanelModel:ShowBuildOptionalEffect(curMapId, optionalGridIds)
    elseif event == XEventId.EVENT_THEATRE4_BUILD_SELECT_GRID then
        local curMapId = args[1]
        local gridIds = args[2]
        self.PanelModel:HideBuildEffect(curMapId)
        self.PanelModel:ShowBuildEffect(curMapId, gridIds)
    elseif event == XEventId.EVENT_THEATRE4_BUILD_END then
        local curMapId = args[1]
        self.PanelModel:HideBuildOptionalEffect(curMapId)
        self.PanelModel:HideBuildEffect(curMapId)
    elseif event == XEventId.EVENT_THEATRE4_OPEN_BUILDING_DETAIL then
        local curMapId = args[1]
        local gridIds = args[2]
        self.PanelModel:ShowBuildDetailEffect(curMapId, gridIds)
    elseif event == XEventId.EVENT_THEATRE4_CLOSE_BUILDING_DETAIL then
        local curMapId = args[1]
        self.PanelModel:HideBuildDetailEffect(curMapId)
    elseif event == XEventId.EVENT_THEATRE4_FOCUS_GRID then
        local mapId = tonumber(args[1])
        local x = tonumber(args[2])
        local y = tonumber(args[3])
        self:FocusCameraGrid(mapId, x, y)
    elseif event == XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_OUT then
        self:PlayOutAnim()
    elseif event == XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_IN then
        self:PlayInAnim()
    elseif event == XEventId.EVENT_THEATRE4_SAVE_CAMERA_POS then
        self.PanelModel:SaveFocusGridBeforeCameraPos()
    elseif event == XEventId.EVENT_THEATRE4_RECOVER_CAMERA_POS then
        self:RecoverFocusGridBeforeCameraPos()
    end
end

function XUiTheatre4Game:OnDisable()
    self._Control:ClearNewAdventureFlag()
    self.EffectScreen.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)
    self.EffectBossTips.gameObject:SetActiveEx(false)
    self.EffectTimeBack.gameObject:SetActiveEx(false)
    for i = 1, 9 do
        local effect = self["EffectPingShan0" .. i]
        if effect then
            effect.gameObject:SetActiveEx(false)
        end
    end
    if self.ProsperityNumber then
        self.ProsperityNumber:StopTimer()
    end
    self.CurProsperity = 0
end

function XUiTheatre4Game:OnDestroy()
    self._Control:ClearAllPopupData()
    self._Control:ClearViewMapData()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_RESTRICT_FOCUS, self.AfterSelectFightReward, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_TIME_BACK, self.PlayTimeBackAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_REFRESH_TIME_LINE, self.RefreshTimeLine, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_PLAY_SCREEN_EFFECT, self.PlayScreenEffect, self)
end

function XUiTheatre4Game:OnReleaseInst()
    return {
        IsFirstOpen = self.IsFirstOpen
    }
end

function XUiTheatre4Game:OnResume(data)
    if data then
        self.IsFirstOpen = data.IsFirstOpen
    end
end

function XUiTheatre4Game:RefreshInfo()
    self.BossInfo:RefreshBoss()
    self.PropInfo:Refresh()
    self:PlayLeftBossEffect()
end

-- 刷新建筑点信息
function XUiTheatre4Game:RefreshBuildPoint()
    -- 建造点图片
    local bpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.BuildPoint)
    if bpIcon then
        self.RImgEnergy:SetRawImage(bpIcon)
    end
    -- 建造点数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.BuildPoint)
end

-- 设置繁荣度数字
function XUiTheatre4Game:SetProsperityNum(num)
    self.TxtScoreNum.text = num
end

-- 设置繁荣度完成
function XUiTheatre4Game:SetProsperityFinish(num)
    self.CurProsperity = num
    self:SetProsperityNum(num)
end

-- 设置觉醒点
function XUiTheatre4Game:RefreshWakeUpPoint()
    if self._Control.EffectSubControl:GetEffectAwakeAvailable() then
        if self.PanelWakeUp then
            self.PanelWakeUp.gameObject:SetActiveEx(true)

            local wakeUpPoint = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.AwakeningPoint)
            self.TxtWakeUpNum.text = wakeUpPoint

            self.PanelModel:ReplaceMapByAwakenValue()
        end
    else
        if self.PanelWakeUp then
            self.PanelWakeUp.gameObject:SetActiveEx(false)
        end
    end
end

-- 刷新繁荣度信息
function XUiTheatre4Game:RefreshProsperity(isAnim)
    -- 繁荣度图片
    local prosperityIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Prosperity)
    if prosperityIcon then
        self.ImgScore:SetRawImage(prosperityIcon)
    end
    -- 繁荣度数字
    local endCount = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Prosperity)
    if isAnim and endCount > self.CurProsperity then
        self:PlayProsperityAnim(self.CurProsperity, endCount)
    else
        if self.ProsperityNumber then
            self.ProsperityNumber:StopTimer()
        end
        self:SetProsperityFinish(endCount)
    end
end

-- 播放繁荣度动画
function XUiTheatre4Game:PlayProsperityAnim(startValue, endValue)
    if not self.ProsperityNumber then
        self.ProsperityNumber = XUiTheatre4RollingNumber.New(function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetProsperityNum(value)
        end, function(value)
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self:SetProsperityFinish(value)
        end)
    end
    local duration = self._Control:GetClientConfig("ProsperityRollingNumberTime", 1, true) / 1000
    self.ProsperityNumber:SetData(startValue, endValue, duration)
end

-- 刷新时间线
function XUiTheatre4Game:RefreshTimeLine()
    if self._IsLockTimeline then
        return
    end
    if not self.PanelTimeLine then
        ---@type XUiPanelTheatre4TimeLine
        self.PanelTimeLine = XUiPanelTheatre4TimeLine.New(self.PanelRoundBar, self)
    end
    self.PanelTimeLine:Open()
    self.PanelTimeLine:Refresh()
end

-- 刷新下一步按钮
function XUiTheatre4Game:RefreshNextBtn()
    -- 行动点图片
    local apIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.ActionPoint)
    if apIcon then
        self.ImgPoint:SetSprite(apIcon)
    end
    -- 行动点
    local ap = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ActionPoint)
    local totalAp = self._Control.AssetSubControl:GetTotalAp()
    self.ImgOn.gameObject:SetActiveEx(ap <= 0)
    self.ImgOff.gameObject:SetActiveEx(ap > 0)
    self.TxtPoint.text = string.format("%d/%d", ap, totalAp)
end

-- 显示事件弹框
function XUiTheatre4Game:ShowEventTip()
    local fateList = self._Control:GetFateList()
    if not fateList or #fateList <= 0 then
        for i = 1, #self._GridFates do
            local grid = self._GridFates[i]
            if grid then
                grid:Close()
            end
        end
        return
    end
    for i = 1, #fateList do
        local fate = fateList[i]
        local grid = self._GridFates[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.PanelEvent, self.PanelEvent.parent)
            grid = XUiPanelTheatre4EventTip.New(ui, self)
            self._GridFates[i] = grid
        end
        grid:Open()
        grid:Refresh(fate)
    end
    for i = #fateList + 1, #self._GridFates do
        local grid = self._GridFates[i]
        if grid then
            grid:Close()
        end
    end
end

-- 显示星级降低提示
function XUiTheatre4Game:ShowStarDownTip()
    local isShow = self._Control:CheckShowStarDownTip()
    self.PanelAchievement.gameObject:SetActiveEx(isShow)
end

-- 检查时间轴是否显示事件弹框
function XUiTheatre4Game:CheckFateShowEventTip()
    self:ShowEventTip()
end

-- 显示起点卡片
function XUiTheatre4Game:ShowStartCard(callback)
    if not self.PanelStartCard then
        ---@type XUiPanelTheatre4GameStartCard
        self.PanelStartCard = XUiPanelTheatre4GameStartCard.New(self.GridStartCard, self)
    end
    self.PanelStartCard:Open()
    self.PanelStartCard:Refresh(callback)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭起点卡片
function XUiTheatre4Game:CloseStartCard()
    if self.PanelStartCard then
        self.PanelStartCard:OnCloseClick()
    end
end

-- 显示建筑卡片
function XUiTheatre4Game:ShowBuildCard(mapId, gridData, callback)
    if not self.PanelBuildCard then
        ---@type XUiPanelTheatre4GameBuildingCard
        self.PanelBuildCard = XUiPanelTheatre4GameBuildingCard.New(self.GridBuildingCard, self)
    end
    self.PanelBuildCard:Open()
    self.PanelBuildCard:Refresh(mapId, gridData, callback)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭建筑卡片
function XUiTheatre4Game:CloseBuildCard()
    if self.PanelBuildCard then
        self.PanelBuildCard:OnCloseClick()
    end
end

-- 打开颜色天赋界面
function XUiTheatre4Game:OnColourClick(colorId)
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    XLuaUiManager.Open("UiTheatre4Genius", colorId)
end

function XUiTheatre4Game:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    self._Control:RegisterClickEvent(self, self.BtnNext, self.OnBtnNextClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLocation, self.OnBtnLocationClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    XUiHelper.RegisterClickEvent(self, self.BtnBacktrack, self.OnBtnTimeBackClick)
    self.BtnSkip.CallBack = function(isOn)
        self:SetSkipSettlement(isOn)
    end
end

function XUiTheatre4Game:OnBtnBackClick()
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    self:Close()
end

-- 建造
function XUiTheatre4Game:OnBtnBuildClick()
    -- 给策划使用 用于查看相机位置距离等信息
    if XEnumConst.Theatre4.IsDebug then
        self.PanelModel:PrintCameraFollowLastPos()
    end
    ---@type UnityEngine.RectTransform
    local rectTransform = self.BtnBuild:GetComponent("RectTransform")
    XLuaUiManager.Open("UiTheatre4BubbleBuild", rectTransform.position, rectTransform.sizeDelta, true)
end

-- 下一步
function XUiTheatre4Game:OnBtnNextClick()
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    -- 行动点
    local actionPoint = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ActionPoint)
    -- 行动点未消耗完, 如果有弹二次确认弹框
    if actionPoint > 0 then
        local title = XUiHelper.GetText("Theatre4PopupCommonTitle")
        local content = XUiHelper.GetText("Theatre4ActionPointRemaining")
        local sureCallback = handler(self, self.OnBtnNextSureClick)
        self._Control:ShowCommonPopup(title, content, sureCallback)
        return
    end
    -- 行动点消耗完, 直接下一步
    self:OnBtnNextSureClick()
end

-- 下一步确认
function XUiTheatre4Game:OnBtnNextSureClick()
    if self._Control.SystemControl:GetIsSkipSettlement() then
        self.BossInfo.IsPlayAnimation = true
    end
    self._Control:DailySettleRequest(function()
        if XMVCA.XTheatre4:CheckAndOpenAdventureSettle() then
            self._Control:ClearDailySettleData()
        else
            if self._Control.SystemControl:GetIsSkipSettlement() then
                self:RefreshDataAfterPopupEndTurn()
                self.BossInfo.IsPlayAnimation = false
            else
                XLuaUiManager.Open("UiTheatre4PopupEndTurn", handler(self, self.RefreshDataAfterPopupEndTurn))
            end
        end
    end)
end

-- 回合结算界面关闭后刷新数据
function XUiTheatre4Game:RefreshDataAfterPopupEndTurn()
    self:CheckFateShowEventTip()
    self:PlayBuildPointEffect()
    self:PlayLeftBossEffect()
    self:ShowStarDownTip()
    self.PanelTimeLine:Refresh(true, function()
        -- 检查是否有弹框
        self._Control:CheckNeedOpenNextPopup()
    end)
end

-- 定位
function XUiTheatre4Game:OnBtnLocationClick()
    local mapId = self._Control:CheckHasArriveNewAreaPopup() and
            self._Control.MapSubControl:GetPreMapId() or self._Control.MapSubControl:GetCurrentMapId()
    local duration = self._Control:GetClientConfig("LocationBtnFocusToMapTime", 1, true) / 1000
    self:FocusToMapBaseCameraPosAndDistance(mapId, duration)
end

-- 关闭 起点卡片和建筑卡片
function XUiTheatre4Game:OnBtnCloseClick()
    self:CloseStartCard()
    self:CloseBuildCard()
    self.BtnClose.gameObject:SetActiveEx(false)
end

-- 处理强制播放事件和弹框
function XUiTheatre4Game:HandleForcePlayEventAndPopup()
    -- 有正在弹的弹框
    if self._Control:CheckPopupOpening() then
        return
    end
    -- 检查是否有强制播放事件
    local mapId, gridId = self._Control.MapSubControl:GetForcePlayEventMapIdAndGridId()
    if XTool.IsNumberValid(mapId) and XTool.IsNumberValid(gridId) then
        self.PanelModel:TriggerGridClick(mapId, gridId)
        return
    end
    -- 检查是否有弹框
    self._Control:CheckNeedOpenNextPopup()
end

--region 播放动画

-- 播放进入动画
---@param isLastFrame boolean 是否最后一帧
function XUiTheatre4Game:PlayInAnim(isLastFrame)
    local nameAnim = "PanelIn"
    if isLastFrame then
        local playable = self:FindPlayable(nameAnim)
        if XTool.UObjIsNil(playable) then
            return
        end
        playable:Stop()
        playable.time = playable.duration - 0.001
        playable:Play()
        playable:Evaluate()
    else
        self:PlayAnimation(nameAnim)
    end
end

-- 播放退出动画
function XUiTheatre4Game:PlayOutAnim()
    self:PlayAnimation("PanelOut")
end

--endregion

--region 相机拖拽缩放相关

-- 设置相机位置和距离
function XUiTheatre4Game:SetCameraPositionAndDistance()
    local cacheCameraPos = self._Control:GetCameraFollowLastPos()
    local mapId = self._Control.MapSubControl:GetCurrentMapId()
    local posX, posY, distance
    if self._Control:CheckIsNewAdventure() then
        posX, posY, distance = self._Control.MapSubControl:GetMapBigCameraPosAndDistance(mapId)
        posX, posY = self.PanelModel:LocalToWorldPointByMapId(mapId, posX, posY)
    elseif self.IsFirstOpen or not cacheCameraPos then
        posX, posY, distance = self._Control.MapSubControl:GetMapCameraPosAndDistance(mapId)
        posX, posY = self.PanelModel:LocalToWorldPointByMapId(mapId, posX, posY)
    else
        posX, posY, distance = cacheCameraPos.PosX, cacheCameraPos.PosY, cacheCameraPos.Distance
    end
    self.PanelModel:SetCameraPositionAndDistance(posX, posY, distance)
    -- 延后一帧刷新相机视野和播放被打断的格子动画 避免相机视野刷新的不对
    XScheduleManager.ScheduleNextFrame(function()
        self.PanelModel:CameraViewRefresh()
        self.PanelModel:PlayInterruptGridAnim(mapId)
    end)
end

-- 刷新定位按钮
---@param isInRange boolean 是否在当前地图范围内
---@param x number 定位按钮位置
function XUiTheatre4Game:RefreshLocationBtn(isInRange, x)
    self.BtnLocation.gameObject:SetActiveEx(not isInRange)
    if isInRange then
        return
    end
    -- 设置定位按钮位置
    self.PanelLocation.anchorMin = CSVector2(x, 0.5)
    self.PanelLocation.anchorMax = CSVector2(x, 0.5)
    self.PanelLocation.pivot = CSVector2(x, 0.5)
    local posX = 0
    if self.PanelLeft then
        posX = x == 0 and self.PanelLeft.anchoredPosition.x * 2 or 0
    end
    self.PanelLocation.anchoredPosition = CSVector2(posX, 0)
end

-- 获取格子的世界坐标
---@param mapId number 地图Id
---@param gridId number 格子Id
---@return number, number X坐标, Y坐标
function XUiTheatre4Game:GetGridWorldPos(mapId, gridId)
    return self.PanelModel:GetGridWorldPos(mapId, gridId)
end

-- 聚焦到地图基础镜头位置和距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiTheatre4Game:FocusToMapBaseCameraPosAndDistance(mapId, duration, ease, callback)
    local posX, posY, distance = self._Control.MapSubControl:GetMapCameraPosAndDistance(mapId)
    posX, posY = self.PanelModel:LocalToWorldPointByMapId(mapId, posX, posY)
    self:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
end

-- 聚焦到地图大镜头位置和距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiTheatre4Game:FocusToMapBigCameraPosAndDistance(mapId, duration, ease, callback)
    local posX, posY, distance = self._Control.MapSubControl:GetMapBigCameraPosAndDistance(mapId)
    posX, posY = self.PanelModel:LocalToWorldPointByMapId(mapId, posX, posY)
    self:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
end

-- 聚焦相机到指定位置
---@param posX number x坐标
---@param posY number y坐标
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiTheatre4Game:FocusCameraToPosition(posX, posY, duration, ease, callback)
    self.PanelModel:FocusCameraToPosition(posX, posY, duration, ease, callback)
end

-- 缩放相机的距离
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiTheatre4Game:ZoomCameraToDistance(distance, duration, ease, callback)
    self.PanelModel:ZoomCameraToDistance(distance, duration, ease, callback)
end

-- 同时聚焦和缩放相机到指定位置和距离
---@param posX number x坐标
---@param posY number y坐标
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiTheatre4Game:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
    self.PanelModel:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
end

-- 聚焦到特定格子
---@param mapId number 地图Id
---@param x number x
---@param y number y
function XUiTheatre4Game:FocusCameraGrid(mapId, x, y)
    if not XTool.IsNumberValid(mapId) then
        return
    end
    local gridId = self._Control.MapSubControl:GetGridIdByPos(mapId, x, y)
    if XTool.IsNumberValid(gridId) then
        local gridX, gridY = self:GetGridWorldPos(mapId, gridId)
        local duration = self._Control:GetClientConfig("LocationBtnFocusToMapTime", 1, true) / 1000

        self:FocusCameraToPosition(gridX, gridY, duration)
    end
end

function XUiTheatre4Game:AfterSelectFightReward()
    if not self:CheckNeedPlayNewAreaAnim() then
        self:RestrictFocus()
    end
end

-- 将相机限制在地图范围内
function XUiTheatre4Game:RestrictFocus()
    local mapId = self._Control.MapSubControl:GetCurrentMapId()
    if not XTool.IsNumberValid(mapId) then
        return
    end
    local posX = self.PanelModel.DragMoveAndZoom.CameraPositionX
    local posY = self.PanelModel.DragMoveAndZoom.CameraPositionY
    local minX, maxX, minY, maxY = self.PanelModel:GetMapSize(mapId)
    if not minX or not maxX or not minY or not maxY then
        return
    end
    posX = XMath.Clamp(posX, minX, maxX)
    posY = XMath.Clamp(posY, minY, maxY)
    --local duration = self._Control:GetClientConfig("LocationBtnFocusToMapTime", 1, true) / 1000
    --self:FocusCameraToPosition(posX, posY, duration)
    local cacheCameraPos = self._Control:GetCameraFollowLastPos()
    if cacheCameraPos then
        self.PanelModel:SetCameraPosition(posX, posY, cacheCameraPos.Distance)
        cacheCameraPos.PosX, cacheCameraPos.PosY = posX, posY
    end
    --XLog.Error("[XUiTheatre4Game] 触发了限制范围")
end

-- 恢复到聚焦到格子前相机的位置
function XUiTheatre4Game:RecoverFocusGridBeforeCameraPos()
    -- 检查是否可以恢复
    if not self._Control:CheckOpenCameraFocusRecover() then
        return
    end
    -- 获取相机聚焦到格子前的位置
    local cameraPos = self._Control:GetFocusGridBeforeCameraPos()
    if XTool.IsTableEmpty(cameraPos) then
        return
    end
    -- 恢复相机位置
    local duration = self._Control:GetClientConfig("RecoverGridLensFocusTime", 1, true) / 1000
    self:FocusCameraToPosition(cameraPos.PosX, cameraPos.PosY, duration)
end

--endregion

--region 特效相关

-- 播放扣血特效
function XUiTheatre4Game:PlayScreenEffectHpDecrease()
    self.EffectScreen.gameObject:SetActiveEx(false)
    self.EffectScreen.gameObject:SetActiveEx(true)
end

-- 显示雪特效
function XUiTheatre4Game:ShowSnowEffect()
    local difficulty = self._Control:GetDifficulty()
    local effectShow = self._Control:GetDifficultySnowEffect(difficulty)
    if not string.IsNilOrEmpty(effectShow) then
        self.EffectSnow:LoadUiEffect(effectShow)
        self.EffectSnow.gameObject:SetActiveEx(true)
    else
        self.EffectSnow.gameObject:SetActiveEx(false)
    end
end

-- 播放云雾隐藏特效
---@param mapGroup number 地图组
---@param mapId number 地图Id
---@param callback function 回调
function XUiTheatre4Game:PlayCloudHideEffect(mapGroup, mapId, callback)
    self.PanelModel:PlayCloudHideEffect(mapGroup, mapId, callback)
end

-- 播放Boss格子特效
---@param mapId number 地图Id
function XUiTheatre4Game:PlayBossGridEffect(mapId)
    local curBossGridData = self._Control.MapSubControl:GetCurrentBossGridData(mapId, true)
    if not curBossGridData then
        return
    end
    local gridId = curBossGridData:GetGridId()
    self.PanelModel:PlayGridEffect(mapId, gridId)
end

-- 播放建造点特效 用于提示建造点过多,提示执行建造
function XUiTheatre4Game:PlayBuildPointEffect()
    local effectShowValue = self._Control:GetClientConfig("BuildPointEffectShowValue", 1, true)
    local curBuildPoint = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.BuildPoint)
    if curBuildPoint >= effectShowValue then
        self.Effect.gameObject:SetActiveEx(false)
        self.Effect.gameObject:SetActiveEx(true)
    end
end

-- 播放左侧边栏的Boss特效
function XUiTheatre4Game:PlayLeftBossEffect()
    local bossGridData = self._Control.MapSubControl:GetCurrentBossGridData()
    if not bossGridData then
        self.EffectBossTips.gameObject:SetActiveEx(false)
        return
    end
    -- BOSS进攻回合数小于等于2的时候出现特效
    local punishCountdown = bossGridData:GetGridPunishCountdown()
    if punishCountdown <= 2 then
        self.EffectBossTips.gameObject:SetActiveEx(true)
    else
        self.EffectBossTips.gameObject:SetActiveEx(false)
    end
end

--endregion

--region 新章节开启相关

-- 播放新章节开启流程
---@param mapGroup number 地图组
---@param mapId number 地图Id
function XUiTheatre4Game:PlayNewChapterOpen(uiName, mapGroup, mapId)
    local bigDuration = self._Control:GetClientConfig("NewAreaFocusToMapBigCameraTime", 1, true) / 1000
    local baseDuration = self._Control:GetClientConfig("NewAreaFocusToMapBaseCameraTime", 1, true) / 1000
    local cueId = self._Control:GetClientConfig("NewAreaFocusCueId", 1, true)
    local cueTag = self._Control.MapSubControl:GetMapCueTag(mapId)
    local ease = CS.DG.Tweening.Ease.InOutQuad
    local asycOpen = asynTask(XLuaUiManager.Open)
    local asycBigCamera = asynTask(self.FocusToMapBigCameraPosAndDistance, self)
    local asycBaseCamera = asynTask(self.FocusToMapBaseCameraPosAndDistance, self)
    local asynPlayEffect = asynTask(self.PlayCloudHideEffect, self)
    RunAsyn(function()
        -- 打开遮罩
        self.Mask.gameObject:SetActiveEx(true)
        -- 检查是否新开的冒险 新开的冒险不播放退出动画
        if not self._Control:CheckIsNewAdventure() then
            self:PlayOutAnim()
        end
        -- 第一步打开当前区域已完成弹框 TODO
        -- 第二步移动到大地图相机位置
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
        asycBigCamera(mapId, bigDuration, ease)
        -- 等待一段时间
        asynWaitSecond(0.3)
        -- 第三步播放云层消失特效
        asynPlayEffect(mapGroup, mapId)
        -- 第四步移动到基础相机位置
        asycBaseCamera(mapId, baseDuration, ease)
        -- 第五步生成新地图同时打开新区域弹框
        self.PanelModel:RefreshMap(mapId)
        -- 关闭遮罩
        self.Mask.gameObject:SetActiveEx(false)
        asycOpen(uiName, mapGroup, mapId)
        self:PlayInAnim()
        XLuaAudioManager.SetWholeSelector("MusicSwitch", cueTag)
        -- 第六步检查是否需要打开下一个弹框
        self._Control:CheckNeedOpenNextPopup()
        -- 清除新开的冒险标记
        if self._Control:CheckIsNewAdventure() then
            self._Control:ClearNewAdventureFlag()
        end
    end)
end

--endregion

--region 查看地图

-- 显示查看地图面板
---@param enterType number 进入类型
function XUiTheatre4Game:ShowViewMapPanel(enterType)
    if not self.PanelBackSelect then
        ---@type XUiPanelTheatre4BackSelect
        self.PanelBackSelect = XUiPanelTheatre4BackSelect.New(self.PanelBack, self)
    end
    self.PanelBackSelect:Open()
    self.PanelBackSelect:Refresh(enterType)
end

-- 关闭查看地图面板
function XUiTheatre4Game:CloseViewMapPanel()
    if self.PanelBackSelect then
        self.PanelBackSelect:Close()
    end
end

--endregion

--region 时间回溯
-- 显示时间回溯面板
function XUiTheatre4Game:RefreshTimeBack()
    if self._Control.EffectSubControl:GetEffectTimeBackAvailable() then
        self.BtnBacktrack.gameObject:SetActiveEx(true)
        -- 时间回溯次数
        local times = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.TimeBack)
        self.TxtBackInTime.text = times
        if times > 0 then
            self.BtnBacktrack:SetButtonState(CS.UiButtonState.Normal)
        else
            self.BtnBacktrack:SetButtonState(CS.UiButtonState.Disable)
        end
    else
        self.BtnBacktrack.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4Game:OnBtnTimeBackClick()
    ---@type UnityEngine.RectTransform
    local rectTransform = self.BtnBacktrack:GetComponent("RectTransform")
    XLuaUiManager.Open("UiTheatre4BubbleBacktrack", rectTransform.position, rectTransform.sizeDelta, true)
end
--endregion

function XUiTheatre4Game:SetSkipSettlement(isOn)
    local value = isOn == 1
    self._Control.SystemControl:SetIsSkipSettlement(value)
    --self.PanelColour.IsPlayAnim = value
    --self.BossInfo.IsPlayAnimation = value
end

function XUiTheatre4Game:PlayTimeBackAnimation(callback)
    local panelModel = self.PanelModel
    local posX = panelModel.DragMoveAndZoom.CameraPositionX
    local posY = panelModel.DragMoveAndZoom.CameraPositionY
    local distance = panelModel.DragMoveAndZoom.CameraDistance
    local duration = 1
    local ease = CS.DG.Tweening.Ease.InOutQuad
    self.EffectTimeBack.gameObject:SetActiveEx(true)
    self._IsLockTimeline = true
    self:FocusAndZoomCamera(posX, posY, 200, duration, ease, function()
        if callback then
            callback()
        end
        -- 播放动画和特效, 还没做
        self:FocusAndZoomCamera(posX, posY, distance, duration, ease, function()
            self.EffectTimeBack.gameObject:SetActiveEx(false)
            self._IsLockTimeline = false
            self.PanelTimeLine:Refresh(true, false, true)
        end)
    end)
end

function XUiTheatre4Game:PlayScreenEffect(effectName)
    if effectName == nil then
        return
    end
    if effectName == "" then
        return
    end
    local effect = self[effectName]
    if effect then
        -- 应该是其中一个
        for i = 1, 9 do
            local effect = self["EffectPingShan0" .. i]
            if effect then
                effect.gameObject:SetActiveEx(false)
            end
        end
        effect.gameObject:SetActiveEx(true)
    else
        XLog.Warning("[XUiTheatre4Game] 缺少对应难度的特效:", tostring(effectName))
    end
end

return XUiTheatre4Game
