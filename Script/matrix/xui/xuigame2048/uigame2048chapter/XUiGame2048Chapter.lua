local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiGame2048Chapter:XLuaUi
---@field _Control XGame2048Control
local XUiGame2048Chapter = XLuaUiManager.Register(XLuaUi, 'UiGame2048Chapter')
local XUiPanelGame2048StageList = require('XUi/XUiGame2048/UiGame2048Chapter/XUiPanelGame2048StageList')
local XUiGameMainSpine = require('XUi/XUiGame2048/UiGame2048Main/XUiGameMainSpine')

function XUiGame2048Chapter:OnAwake()
    self.BtnBack.CallBack = handler(self, self.OnCloseEvent)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:BindHelpBtn(self.BtnHelp, "Game2048")
    self.PanelSpine = XUiGameMainSpine.New(self.UiGame2048ChapterSpine)
end

function XUiGame2048Chapter:OnStart(chapterId, chapterIndex)
    self._ChapterId = chapterId
    self._ChapterIndex = chapterIndex
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCurActivityItemId())
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)

    if self.TitleBg then
        self.TitleBg:SetRawImage(self._Control:GetChapteTitleIconById(self._ChapterId))
    end
    
    self.Bg:SetRawImage(self._Control:GetChapterFullBgById(self._ChapterId))
    self._Control:SetCurChapterId(self._ChapterId)
    self:InitStages()
    self.PanelSpine:PlaySpineAnimation("Enable", "Loop")
end

function XUiGame2048Chapter:OnEnable()
    self:RefreshStages()
    self.TxtStarNum.text = XUiHelper.FormatText(self._Control:GetClientConfigText('ChapterProgressShowLabel'), self._Control:GetChapterCurStarSummary(self._ChapterId), self._Control:GetChapterStarTotalById(self._ChapterId))

    self._Control:AddEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_UNSELECT_STAGE, self.OnCloseEvent, self)
end

function XUiGame2048Chapter:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XGame2048.EventIds.EVENT_GAME2048_UNSELECT_STAGE, self.OnCloseEvent, self)
end

function XUiGame2048Chapter:InitStages()
    self.GridStage.gameObject:SetActiveEx(false)
    
    local stageRootGO = nil
    -- 获取对应章节的根节点，其他隐藏
    for i = 1, 100 do
        
        local panelGO = self['PanelChapter'..i]

        if panelGO then
            panelGO.gameObject:SetActiveEx(false)

            if i == self._ChapterIndex then
                stageRootGO = panelGO
            end
        else
            break
        end
    end
    
    -- 根据当前章节根节点初始化关卡
    if stageRootGO then
        self._StageList = XUiPanelGame2048StageList.New(stageRootGO, self, self._ChapterId)
        self._StageList:Open()
    end
end

function XUiGame2048Chapter:RefreshStages()
    self._StageList:RefreshStages()
end

function XUiGame2048Chapter:OnCloseEvent()
    if not XLuaUiManager.IsUiShow('UiGame2048StageDetail') then
        self:Close()
    else
        self._StageList:CancelSelect()
    end
end

return XUiGame2048Chapter