local XUiAssignBuff = XLuaUiManager.Register(XLuaUi, "UiAssignBuff")

local XUiAssignBuffPart = require("XUi/XUiAssign/XUiAssignBuffPart")
local XUiAssignBuffAll = require("XUi/XUiAssign/XUiAssignBuffAll")

local INDEX_PART = 1
local INDEX_ALL = 2

function XUiAssignBuff:OnAwake()
    self:InitComponent()
end

function XUiAssignBuff:OnStart()
end

function XUiAssignBuff:OnEnable()
    self:Refresh()
end

function XUiAssignBuff:OnDisable()
    XDataCenter.FubenAssignManager.SelectChapterId = nil
end

function XUiAssignBuff:InitComponent()
    -- self.BtnClose.CallBack = function() self:Close() end -- 点击背景关闭
    self.BtnTanchuangClose.CallBack = function() self:Close() end

    self.ImgEmpty.gameObject:SetActiveEx(false)


    local tags = { self.BtnTab01, self.BtnTab02 }
    self.PanelTag:Init(tags, function(index) self:PageTurn(index) end)

    self.PanelPart = XUiAssignBuffPart.New(self, self.PanelPart)
    self.PanelPart:Close()

    self.PanelAll = XUiAssignBuffAll.New(self, self.PanelAll)
    self.PanelAll:Close()
end

function XUiAssignBuff:OnGetEvents()
    return { XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END }
end

function XUiAssignBuff:OnNotify(evt)
    if evt == XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END then
        self:OnOccupySelected()
    end
end

function XUiAssignBuff:Refresh()
    self.PanelTag:SelectIndex(INDEX_PART, true)
end

function XUiAssignBuff:PageTurn(index)
    local hasList = false
    if index == INDEX_PART then
        hasList = self.PanelPart:Show()
        self.PanelAll:Close()
    elseif index == INDEX_ALL then
        hasList = self.PanelAll:Show()
        self.PanelPart:Close()
    end
    self.ImgEmpty.gameObject:SetActiveEx(not hasList)
end

function XUiAssignBuff:OnOccupySelected()
    local chapterId = XDataCenter.FubenAssignManager.SelectChapterId
    local characterId = XDataCenter.FubenAssignManager.SelectCharacterId
    local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
    chapterData:SetCharacterId(characterId)
    self:Refresh()
end