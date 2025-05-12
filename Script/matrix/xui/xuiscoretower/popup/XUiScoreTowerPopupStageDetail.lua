local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridScoreTowerCharacter = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter")
---@class XUiScoreTowerPopupStageDetail : XLuaUi
---@field private _Control XScoreTowerControl
---@field VideoComponent XVideoPlayerUGUI
local XUiScoreTowerPopupStageDetail = XLuaUiManager.Register(XLuaUi, "UiScoreTowerPopupStageDetail")

function XUiScoreTowerPopupStageDetail:OnAwake()
    self:RegisterUiEvents()
    self.BtnClose.gameObject:SetActiveEx(false)
    self.BtnCloseVideo.gameObject:SetActiveEx(false)
    self.BtnCloseBuffDetail.gameObject:SetActiveEx(false)
    self.BubbleChooseCharacter.gameObject:SetActiveEx(false)
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.BubbleBuffDetail.gameObject:SetActiveEx(false)
    self.GridBuffDetail.gameObject:SetActiveEx(false)
    self.BubbleVideo.gameObject:SetActiveEx(false)
    self.VideoPlayer.gameObject:SetActiveEx(false)
end

---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 层Id
---@param stageId number 关卡Id ScoreTowerStage表的ID
function XUiScoreTowerPopupStageDetail:OnStart(chapterId, towerId, floorId, stageId)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.FloorId = floorId
    self.StageId = stageId
    self.StageType = self._Control:GetStageType(stageId)

    ---@type XUiPanelScoreTowerStageNormal
    self.PanelStageNormalUi = nil
    ---@type XUiPanelScoreTowerStageBoss
    self.PanelStageBossUi = nil
    self:InitDynamicTable()
    ---@type UiObject[]
    self.GridBuffDetailList = {}
end

function XUiScoreTowerPopupStageDetail:OnEnable()
    self:RefreshPlugInPoint()
    if self.StageType == XEnumConst.ScoreTower.StageType.Normal then
        self:OpenNormalStagePanel()
    elseif self.StageType == XEnumConst.ScoreTower.StageType.Boss then
        self:OpenBossStagePanel()
    else
        XLog.Error(string.format("error: stage type is invalid, stageId: %s, stageType: %s", self.StageId, self.StageType))
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SCORE_TOWER_OPEN_STAGE_DETAIL, self.StageId, self.StageType)
end

function XUiScoreTowerPopupStageDetail:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_SCORE_TOWER_CLOSE_STAGE_DETAIL)
    self.VideoComponent = nil
    self.StageTeam = nil
end

-- 刷新插件点数
function XUiScoreTowerPopupStageDetail:RefreshPlugInPoint()
    if not self.PlugPointAsset then
        ---@type XUiPanelScoreTowerPlugPointAsset
        self.PlugPointAsset = require("XUi/XUiScoreTower/Common/XUiPanelScoreTowerPlugPointAsset").New(self.BtnTool, self)
    end
    self.PlugPointAsset:Open()
    self.PlugPointAsset:Refresh(self.ChapterId, self.TowerId, self.FloorId)
end

-- 刷新插件点数 by PlugIds
function XUiScoreTowerPopupStageDetail:RefreshPlugInPointByPlugIds(plugIds)
    if self.PlugPointAsset then
        self.PlugPointAsset:RefreshCountByPlugIds(plugIds)
    end
end

-- 打开普通关卡面板
function XUiScoreTowerPopupStageDetail:OpenNormalStagePanel()
    if not self.PanelStageNormalUi then
        self.PanelStageNormalUi = require("XUi/XUiScoreTower/Popup/XUiPanelScoreTowerStageNormal").New(self.PanelStageNormal, self)
    end
    self.PanelStageNormalUi:Open()
    self.PanelStageNormalUi:Refresh(self.ChapterId, self.TowerId, self.FloorId, self.StageId)
end

-- 刷新普通关卡
function XUiScoreTowerPopupStageDetail:RefreshNormalStage()
    if self.PanelStageNormalUi and self.PanelStageNormalUi:IsNodeShow() then
        self.PanelStageNormalUi:RefreshOther()
    end
end

-- 打开Boss关卡面板
function XUiScoreTowerPopupStageDetail:OpenBossStagePanel()
    if not self.PanelStageBossUi then
        self.PanelStageBossUi = require("XUi/XUiScoreTower/Popup/XUiPanelScoreTowerStageBoss").New(self.PanelStageBoss, self)
    end
    self.PanelStageBossUi:Open()
    self.PanelStageBossUi:Refresh(self.ChapterId, self.TowerId, self.FloorId, self.StageId)
end

function XUiScoreTowerPopupStageDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.BubbleChooseCharacter)
    self.DynamicTable:SetProxy(XUiGridScoreTowerCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

---@param entityId number 实体Id
function XUiScoreTowerPopupStageDetail:SetupDynamicTable(entityId)
    ---@type { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }[]
    self.CharacterList = self._Control:GetStageShowCharacterInfoList(self.ChapterId, self.TowerId, self.FloorId, self.StageId, self.StageTeam)
    self.DynamicTable:SetDataSource(self.CharacterList)
    self.DynamicTable:ReloadDataSync(self:GetDefaultFocusPos(entityId))
end

-- 获取默认聚焦的位置
---@param entityId number 实体Id
function XUiScoreTowerPopupStageDetail:GetDefaultFocusPos(entityId)
    if not XTool.IsNumberValid(entityId) then
        return 1
    end
    for i, character in ipairs(self.CharacterList) do
        if character.Id == entityId then
            return i
        end
    end
    return 1
end

-- 通过Pos获取Index
---@param pos number
function XUiScoreTowerPopupStageDetail:GetIndexByPos(pos)
    if not XTool.IsNumberValid(pos) then
        return 0
    end
    for index, teamPos in pairs(self.IndexMapping) do
        if teamPos == pos then
            return index
        end
    end
    return pos
end

---@param grid XUiGridScoreTowerCharacter
function XUiScoreTowerPopupStageDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local character = self.CharacterList[index]
        grid:Refresh(character.Id, character.Pos)
        grid:SetUse(character.IsUsed)
        grid:SetNow(character.IsNow)
        grid:SetIsRecommend(self._Control:IsStageSuggestTag(self.StageId, character.Id))
        local isTeam, pos = self.StageTeam:GetEntityIdIsInTeam(character.Id)
        grid:SetIsInTeam(isTeam, self:GetIndexByPos(pos))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnCharacterGridClick(self.CharacterList[index], grid)
    end
end

-- 点击角色
---@param character { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }
---@param grid XUiGridScoreTowerCharacter 角色格子
function XUiScoreTowerPopupStageDetail:OnCharacterGridClick(character, grid)
    local isTeam, pos = self.StageTeam:GetEntityIdIsInTeam(character.Id)
    if isTeam then
        if character.IsNow then
            self:ResetStageSecondConfirm(self.StageId, 2)
            return
        end
        -- 容错处理，如果关卡已通关，不允许移除角色
        if self._Control:IsStagePass(self.ChapterId, self.TowerId, self.StageId) then
            XUiManager.TipMsg(self._Control:GetClientConfig("StageTeamRelatedTips", 2))
            return
        end
        self.StageTeam:RemoveStageEntityId(character.Id, pos)
        grid:SetIsInTeam(false)
    else
        -- 判断当前关卡队伍是否已满
        if self.StageTeam:GetIsFullMember() then
            XUiManager.TipMsg(self._Control:GetClientConfig("StageTeamRelatedTips", 1))
            return
        end
        if character.IsUsed then
            self:ResetStageSecondConfirm(character.StageId, 1)
            return
        end
        pos = self.StageTeam:AddStageEntityId(character.Id, self.IndexMapping)
        if pos <= 0 then
            XLog.Error(string.format("error: add stage entity id failed, entityId: %s, stageId: %s", character.Id, self.StageId))
        end
        grid:SetIsInTeam(true, self:GetIndexByPos(pos))
    end
    self:RefreshNormalStage()
    -- 播放音效
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Fight_PageSwitch_Up)
end

-- 重置关卡的二级确认弹框
---@param stageId number 关卡Id ScoreTowerStage表的ID
---@param tipIndex number 提示索引
function XUiScoreTowerPopupStageDetail:ResetStageSecondConfirm(stageId, tipIndex)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    local title = self._Control:GetClientConfig("ResetStageSecondConfirmTitle", tipIndex)
    local content = self._Control:GetClientConfig("ResetStageSecondConfirmContent", tipIndex)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:ResetStageTeamRequest(self.ChapterId, self.TowerId, stageId, function()
            if self.PlugPointAsset then
                self.PlugPointAsset:RefreshCount()
            end
            self:SetupDynamicTable()
        end)
    end)
end

-- 刷新Buff详情
function XUiScoreTowerPopupStageDetail:RefreshBuffDetail(removeAffixIds)
    local bossAffixList = self._Control:GetStageBossAffixEvent(self.StageId)
    if XTool.IsTableEmpty(bossAffixList) then
        return
    end
    for index, affixId in pairs(bossAffixList) do
        local buff = self.GridBuffDetailList[index]
        if not buff then
            buff = XUiHelper.Instantiate(self.GridBuffDetail, self.BubbleBuffDetail)
            self.GridBuffDetailList[index] = buff
        end
        buff.gameObject:SetActiveEx(true)
        local icon = self._Control:GetFightEventIcon(affixId)
        if not string.IsNilOrEmpty(icon) then
            buff:GetObject("RImgBuff"):SetRawImage(icon)
        end
        buff:GetObject("TxtTitle").text = self._Control:GetFightEventName(affixId)
        buff:GetObject("TxtDetail").text = self._Control:GetFightEventDesc(affixId)
        buff:GetObject("PanelDisable").gameObject:SetActiveEx(table.contains(removeAffixIds, affixId))
    end
    for i = #bossAffixList + 1, #self.GridBuffDetailList do
        self.GridBuffDetailList[i].gameObject:SetActiveEx(false)
    end
end

-- 播放视频之前
function XUiScoreTowerPopupStageDetail:PlayVideoBefore(pluginId)
    if not XTool.IsNumberValid(pluginId) then
        return
    end
    local videoUrl = self._Control:GetPlugVideo(pluginId)
    if string.IsNilOrEmpty(videoUrl) then
        return
    end
    self.TxtDetail.text = self._Control:GetPlugDesc(pluginId)
    if not self.VideoComponent then
        self.VideoComponent = XUiHelper.Instantiate(self.VideoPlayer, self.PanelVideo)
        self:PlayVideo(videoUrl)
    else
        self:PlayVideo(videoUrl, true)
    end
end

-- 播放视频
function XUiScoreTowerPopupStageDetail:PlayVideo(videoUrl, isReplay)
    if self.VideoComponent then
        self.VideoComponent.gameObject:SetActiveEx(true)
        self.VideoComponent:SetVideoFromRelateUrl(videoUrl)
        if isReplay then
            self.VideoComponent:RePlay()
        else
            self.VideoComponent:Play()
        end
    end
end

-- 停止视频
function XUiScoreTowerPopupStageDetail:StopVideo()
    if self.VideoComponent then
        self.VideoComponent:Pause()
        self.VideoComponent.gameObject:SetActiveEx(false)
    end
end

--region 子类调用

-- 显示成员气泡
---@param entityId number 实体Id
---@param stageTeam XScoreTowerStageTeam 关卡队伍
---@param indexMapping table<number, number> 位置映射
function XUiScoreTowerPopupStageDetail:ShowBubbleChooseCharacter(entityId, stageTeam, indexMapping)
    self.BubbleChooseCharacter.gameObject:SetActiveEx(true)
    self.StageTeam = stageTeam
    self.IndexMapping = indexMapping
    self:SetupDynamicTable(entityId)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭成员气泡
function XUiScoreTowerPopupStageDetail:CloseBubbleChooseCharacter()
    if self.DynamicTable then
        self.DynamicTable:RecycleAllTableGrid()
    end
    self.BubbleChooseCharacter.gameObject:SetActiveEx(false)
    self.CharacterList = nil
    self.StageTeam = nil
    self.IndexMapping = nil
end

-- 显示Buff气泡
function XUiScoreTowerPopupStageDetail:ShowBubbleBuffDetail(removeAffixIds)
    self.BubbleBuffDetail.gameObject:SetActiveEx(true)
    self:RefreshBuffDetail(removeAffixIds)
    self.BtnCloseBuffDetail.gameObject:SetActiveEx(true)
end

-- 关闭Buff气泡
function XUiScoreTowerPopupStageDetail:CloseBubbleBuffDetail()
    self.BubbleBuffDetail.gameObject:SetActiveEx(false)
end

-- 显示视频气泡
---@param pluginId number 插件Id
function XUiScoreTowerPopupStageDetail:ShowBubbleVideo(pluginId)
    self.BubbleVideo.gameObject:SetActiveEx(true)
    self:PlayVideoBefore(pluginId)
    self.BtnCloseVideo.gameObject:SetActiveEx(true)
end

-- 关闭视频气泡
function XUiScoreTowerPopupStageDetail:CloseBubbleVideo()
    self:StopVideo()
    self.BubbleVideo.gameObject:SetActiveEx(false)
end

-- 扫荡成功后的处理
function XUiScoreTowerPopupStageDetail:OnSweepSuccess()
    XUiManager.TipMsg(self._Control:GetClientConfig("SweepSuccessTip"))
    self:Close()
end

--endregion

function XUiScoreTowerPopupStageDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnCloseVideo, self.OnBtnCloseVideoClick)
    self:RegisterClickEvent(self.BtnCloseBuffDetail, self.OnBtnCloseBuffDetailClick)
end

function XUiScoreTowerPopupStageDetail:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerPopupStageDetail:OnBtnCloseClick()
    self.BtnClose.gameObject:SetActiveEx(false)
    self:CloseBubbleChooseCharacter()
end

function XUiScoreTowerPopupStageDetail:OnBtnCloseVideoClick()
    self.BtnCloseVideo.gameObject:SetActiveEx(false)
    self:CloseBubbleVideo()
end

function XUiScoreTowerPopupStageDetail:OnBtnCloseBuffDetailClick()
    self.BtnCloseBuffDetail.gameObject:SetActiveEx(false)
    self:CloseBubbleBuffDetail()
end

return XUiScoreTowerPopupStageDetail
