---@class XUiRogueSimChapter : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimChapter = XLuaUiManager.Register(XLuaUi, "UiRogueSimChapter")

function XUiRogueSimChapter:OnAwake()
    self:RegisterUiEvents()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.RogueSimCoin }, self.PanelSpecialTool, self)

    ---@type XUiGridRogueSimChapter[]
    self.GridChapterList = {}
end

function XUiRogueSimChapter:OnStart()
    self.StageIds = self._Control:GetActivityStageIds()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshGridTime()
        end
    end)
end

function XUiRogueSimChapter:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshChapter()
end

function XUiRogueSimChapter:OnDisable()
    self.Super.OnDisable(self)
    if XLuaUiManager.IsUiShow("UiRogueSimChapterDetail") then
        XLuaUiManager.Remove("UiRogueSimChapterDetail")
    end
end

function XUiRogueSimChapter:RefreshChapter()
    if XTool.IsTableEmpty(self.StageIds) then
        return
    end
    for index, stageId in ipairs(self.StageIds) do
        local grid = self.GridChapterList[index]
        if not grid then
            local go = self["GridChapter" .. index]
            grid = require("XUi/XUiRogueSim/Chapter/XUiGridRogueSimChapter").New(go, self, handler(self, self.ClickStageGrid))
            self.GridChapterList[index] = grid
        end
        grid:Open()
        grid:Refresh(stageId)
    end
    for i = #self.StageIds + 1, #self.GridChapterList do
        self.GridChapterList[i]:Close()
    end
end

-- 点击关卡
---@param grid XUiGridRogueSimChapter
function XUiRogueSimChapter:ClickStageGrid(grid)
    -- 打开详情面板
    if not XLuaUiManager.IsUiShow("UiRogueSimChapterDetail") then
        XLuaUiManager.Open("UiRogueSimChapterDetail", grid.StageId)
    end
end

-- 刷新格子倒计时
function XUiRogueSimChapter:RefreshGridTime()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    for _, grid in pairs(self.GridChapterList) do
        if grid:IsNodeShow() then
            grid:RefreshTime()
        end
    end
end

function XUiRogueSimChapter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiRogueSimChapter:OnBtnBackClick()
    self:Close()
end

function XUiRogueSimChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiRogueSimChapter
