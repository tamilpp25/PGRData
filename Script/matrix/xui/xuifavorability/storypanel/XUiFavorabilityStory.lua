---@class XUiFavorabilityStory: XUiNode
---@field _Control XFavorabilityControl
local XUiFavorabilityStory=XLuaUiManager.Register(XLuaUi,"UiFavorabilityStory")
local XUiPanelFavorabilityStoryList = require('XUi/XUiFavorability/StoryPanel/XUiPanelFavorabilityStoryList')
local XUiPanelFavorabilityStoryReward = require('XUi/XUiFavorability/StoryPanel/XUiPanelFavorabilityStoryReward')
local XUiPanelFavorabilityStoryDetail = require('XUi/XUiFavorability/StoryPanel/PanelStoryDetail/XUiPanelFavorabilityStoryDetail')
local XUiPanelBgNormal = require('XUi/XUiFavorability/StoryPanel/PanelBg/XUiPanelBgNormal')
local XUiPanelFavorabilityRegional = require('XUi/XUiFavorability/StoryPanel/XUiPanelFavorabilityRegional')

local lastPosX = 0 --上一次关闭前content的x坐标
local shouldResume=false

--region 生命周期
function XUiFavorabilityStory:OnAwake()
    self:InitCb()
end

function XUiFavorabilityStory:OnStart(currentCharacterId)
    self.CurrentCharacterId=currentCharacterId
    self:InitStoryList()
    self:InitStoryReward()
    self:InitStoryDetail()
    self:InitPanelBg()
    self:RefreshBaseData()
end

function XUiFavorabilityStory:OnEnable()
    self._Control:AddEventListener(XControlEventId.EVENT_OPEN_STORY_DETAIL, self.OnOpenStoryDetailEvent, self)
    self:RefreshList()
    self.RegionalPanel:RefreshStoryData()
end

function XUiFavorabilityStory:OnDisable()
    self._Control:RemoveEventListener(XControlEventId.EVENT_OPEN_STORY_DETAIL, self.OnOpenStoryDetailEvent, self)
end
--endregion

--region 初始化
function XUiFavorabilityStory:InitCb()
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
end

function XUiFavorabilityStory:InitStoryList()
    local config = self._Control:GetStoryLayoutCfgById(self.CurrentCharacterId)
    self.FavorabilityStoryStage = self.PanelChapter:LoadPrefab(config.LayOutType)
    self._PanelStoryList = XUiPanelFavorabilityStoryList.New(self.FavorabilityStoryStage, self, self.CurrentCharacterId)
    self._PanelStoryList:Open()
end

function XUiFavorabilityStory:InitStoryReward()
    self._PanelStoryReward = XUiPanelFavorabilityStoryReward.New(self.PanelReward, self, self.CurrentCharacterId)
    if self._Control:CheckStoryHasRewardTask(self.CurrentCharacterId) then
        self._PanelStoryReward:Open()
    else
        self._PanelStoryReward:Close()
    end
end

function XUiFavorabilityStory:InitStoryDetail()
    --self._PanelStoryDetail = XUiPanelFavorabilityStoryDetail.New(self.PanelStoryDialog, self)
    --self._PanelStoryDetail:Close()
end

function XUiFavorabilityStory:InitPanelBg()
    ---@type XTableStoryLayout
    local layoutCfg = self._Control:GetStoryLayoutCfgById(self.CurrentCharacterId)

    if layoutCfg then
        ---@type XTableStoryLayoutBgType
        local bgTypeCfg = self._Control:GetStoryLayoutBgTypeCfg(layoutCfg.BgType)

        if bgTypeCfg then
            local go = self.PanelBgRoot:LoadPrefab(bgTypeCfg.PrefabAddress)
            XUiHelper.SetCanvasesSortingOrder(go.transform)
            
            self._PanelBg = XUiPanelBgNormal.New(go, self, self.CurrentCharacterId, bgTypeCfg, layoutCfg.BgCustomParams)
            self._PanelBg:Open()
        end
    end
    
    self.RegionalPanel = XUiPanelFavorabilityRegional.New(self.PanelRegional, self)
end
--endrgion

--region 数据更新
function XUiFavorabilityStory:RefreshList()
    local needResume=self:IsTriggerReusme()
    if needResume then
        self._PanelStoryList:SetLayoutHorizontalPos(lastPosX)
    end
end

function XUiFavorabilityStory:RefreshBaseData()
    self.RegionalPanel:RefreshTitle()
end

--endregion

--region 事件
function XUiFavorabilityStory:SetResumeTrigger(trigger, posX)
    shouldResume = trigger
    if trigger then
        lastPosX = posX
    end
end

function XUiFavorabilityStory:IsTriggerReusme()
    if shouldResume then
        shouldResume=false
        return true
    end
    return false
end

---@param cfg XTableCharacterStory
function XUiFavorabilityStory:OnOpenStoryDetailEvent(cfg)
    if self._CurDetailType ~= cfg.StageDetailType then
        ---@type XTableCharacterStoryStageDetailType
        local stageDetailTypeCfg = self._Control:GetStageDetailTypeCfg(cfg.StageDetailType)

        if stageDetailTypeCfg then
            local go = self.PanelStoryDialogRoot:LoadPrefab(stageDetailTypeCfg.PrefabAddress)

            if self._PanelStoryDetail then
                self:RemoveChildNode(self._PanelStoryDetail)
            end
            self._PanelStoryDetail = XUiPanelFavorabilityStoryDetail.New(go, self)
        end
    end
    self._PanelStoryDetail:Open()
    self._PanelStoryDetail:Refresh(cfg)
end
--endregion


return XUiFavorabilityStory

