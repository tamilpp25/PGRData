local XUiPanelNieRRepeatBanner = XClass(nil, "XUiPanelNieRRepeatBanner")
local XUiGridNierRepeatMainStage = require("XUi/XUiNieR/XUiRepeat/XUiGridNierRepeatMainStage")
local XUiGridNierRepeatStage = require("XUi/XUiNieR/XUiRepeat/XUiGridNierRepeatStage")
function XUiPanelNieRRepeatBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    
    self.StageList = {}
    for index = 1, 4 do
        self.StageList[index] = self["GridMainLineBanner"..index]
    end
    self.RepeatStageEx = {}
end

function XUiPanelNieRRepeatBanner:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPanelNieRRepeatBanner:Refresh(repeatMainStage)
    local chapterProxy
    if not self.RepeatChapter then
        chapterProxy = XUiGridNierRepeatMainStage.New(self.GridMainLineBannerRepeat1, self.RootUi)
        self.RepeatChapter = chapterProxy
    else
        chapterProxy = self.RepeatChapter
    end
    chapterProxy:UpdateInfo(repeatMainStage)

    local stageProxy
    for index = 1, 4 do
        if not self.RepeatStageEx[index] then
            stageProxy = XUiGridNierRepeatStage.New(self.StageList[index], self.RootUi)
            self.RepeatStageEx[index] = stageProxy
        else
            stageProxy = self.RepeatStageEx[index]
        end
        
        stageProxy:UpdateInfo(repeatMainStage, index)
    end
end

function XUiPanelNieRRepeatBanner:PlayLoopAnim()
    self.AnimEnable.gameObject:SetActiveEx(false)
    self.AnimEnable.gameObject:SetActiveEx(true)
    self.IconLoop.gameObject:PlayTimelineAnimation(function()
        
    end)
end

return XUiPanelNieRRepeatBanner