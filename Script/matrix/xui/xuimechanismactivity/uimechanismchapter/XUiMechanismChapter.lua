local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiMechanismChapter
---@field _Control XMechanismActivityControl
local XUiMechanismChapter = XLuaUiManager.Register(XLuaUi, 'UiMechanismChapter')
local XUiPanelMechanismStageList = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiPanelMechanismStageList')
local XUiPanelTeamList = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiPanelTeamList')
--region --------------------------生命周期---------------------------
function XUiMechanismChapter:OnAwake()
    self.BtnBack.CallBack = handler(self, self.OnClose)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    XUiHelper.RegisterHelpButton(self.BtnHelp, 'MechanismActivity')
end

function XUiMechanismChapter:OnStart(chapterId)
    self._ChapterId = chapterId
    self._ResourcesPanel = XUiPanelAsset.New(self, self.PanelAsset, self._Control:GetCoinItemByActivityId(self._Control:GetCurActivityId()))
    self.TxtTitle.text = self._Control:GetChapterNameById(self._ChapterId)
    --todo：设置章节背景
    self._PanelStageList = XUiPanelMechanismStageList.New(self.ListBarrier, self)
    self._PanelTeamList = XUiPanelTeamList.New(self.PanelTeam, self)
    self._PanelTeamList:InitTeamDataByChapterId(self._ChapterId)
    
    -- 缓存当前章节Id，用于编队界面拿到并获取指定的角色列表
    self._Control:SetMechanismCurChapterId(self._ChapterId)
end

function XUiMechanismChapter:OnEnable()
    self._PanelTeamList:Refresh()
end
--endregion

function XUiMechanismChapter:OnClose()
    if XLuaUiManager.IsUiShow('UiMechanismChapterDetail') then
        self._PanelStageList:SetSelectStage(nil)
    else
        self:Close()
    end
end

function XUiMechanismChapter:HideTeamPanel()
    self._PanelTeamList:Close()
    self.ImgBg.gameObject:SetActiveEx(false)
end

function XUiMechanismChapter:ShowTeamPanel()
    self.ImgBg.gameObject:SetActiveEx(true)
    self._PanelTeamList:Open()
end

return XUiMechanismChapter