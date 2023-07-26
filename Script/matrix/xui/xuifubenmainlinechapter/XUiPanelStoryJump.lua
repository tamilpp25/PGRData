local pairs = pairs
local tableInsert = table.insert

local XUiGridStoryJump = require("XUi/XUiFubenMainLineChapter/XUiGridStoryJump")
---@class XUiPanelStoryJump
---@field GridStoryJumpBtn XUiGridStoryJump[]
local XUiPanelStoryJump = XClass(nil, "XUiPanelStoryJump")

function XUiPanelStoryJump:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GridStoryJumpBtn = {}

    self.DelayTime = XUiHelper.GetClientConfig("StoryJumpPopupTipsDelayTime", XUiHelper.ClientConfigType.Int)
    -- 默认为隐藏
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStoryJump:GetConfig()
    if self.Type == XFubenConfigs.ChapterType.MainLine then
        return XFubenMainLineConfigs.GetNextChapterCfgByChapterId(self.ChapterId)
    elseif self.Type == XFubenConfigs.ChapterType.ShortStory then
        return XFubenShortStoryChapterConfigs.GetNextChapterCfgByChapterId(self.ChapterId)
    elseif self.Type == XFubenConfigs.ChapterType.ExtralChapter then
        return XFubenExtraChapterConfigs.GetNextChapterCfgByChapterId(self.ChapterId)
    end
    return nil
end

function XUiPanelStoryJump:Refresh(chapterId, type, secondMainId)
    self.ChapterId = chapterId
    self.Type = type
    self.Config = self:GetConfig()
    
    -- 默认为隐藏
    self.GameObject:SetActiveEx(false)
    if XTool.IsTableEmpty(self.Config) then
        return
    end
    if XTool.IsNumberValid(secondMainId) and XTool.IsNumberValid(self.Config.TRPGChapterId) then
        if secondMainId ~= self.Config.TRPGChapterId then
            return
        end
    end
    if not self:CheckSkipCondition() then
        return
    end
    -- 刷新信息
    self:RefreshButton()
    
    if not self:CheckIsPopupTip() then
        -- 弹出提示
        self:ShowPopupTip()
    end
end

function XUiPanelStoryJump:RefreshButton()
    local btnData = {}
    local storyData = {} -- 主线、浮点、外篇 剧情
    local prequeldata = {} -- 简章 剧情

    for index, chapterId in pairs(self.Config.StoryChapterId) do
        local chapterType = self.Config.StoryChpterType[index]
        local tempData = {
            ImgPath = self.Config.StoryImgs[index],
            SkipId = self.Config.StorySkipId[index],
            SkipName = self.Config.StorySkipName[index],
            ChapterType = chapterType,
            ChapterId = chapterId
        }
        if chapterType == XFubenConfigs.ChapterType.Prequel then
            tableInsert(prequeldata, tempData)
        else
            tableInsert(storyData, tempData)
        end
    end
    btnData = XTool.MergeArray(prequeldata, storyData)

    if XTool.IsTableEmpty(btnData) then
        return
    end
    
    -- 显示跳转按钮
    for index, data in pairs(btnData) do
        local grid = self.GridStoryJumpBtn[index]
        if not grid then
            local go = index == 1 and self.BtnStoryJump or XUiHelper.Instantiate(self.BtnStoryJump, self.PanelNodeList)
            grid = XUiGridStoryJump.New(go, self)
            self.GridStoryJumpBtn[index] = grid
        end
        grid:Refresh(data)
        grid.GameObject:SetActiveEx(true)
    end
    for i = #btnData + 1, #self.GridStoryJumpBtn do
        self.GridStoryJumpBtn[i].GameObject:SetActiveEx(false)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiPanelStoryJump:CheckSkipCondition()
    local skipCondition = self.Config.SkipCondition
    return XConditionManager.CheckCondition(skipCondition)
end

function XUiPanelStoryJump:CheckIsPopupTip()
    return self:GetNextChapterLocalData()
end

function XUiPanelStoryJump:ShowPopupTip()
    local nextData, hideData, prequeldata = self:GetShowPopupData()
    local showData = {} -- 提示信息
    self:GetShowData(nextData, XUiHelper.GetText("UiFubenStoryJumpPopupNextTitle"), showData)
    self:GetShowData(hideData, XUiHelper.GetText("UiFubenStoryJumpPopupHideTitle"), showData)
    self:GetShowData(prequeldata, XUiHelper.GetText("UiFubenStoryJumpPopupPrequelTitle"), showData)
    if XTool.IsTableEmpty(showData) then
        return
    end
    -- 显示提示
    XLuaUiManager.Open("UiLeftPopupTips", showData, self.DelayTime)
    -- 保存
    self:SaveNextChapterLocalData()
end

function XUiPanelStoryJump:GetShowPopupData()
    local nextData = {} -- 下一章 剧情
    local hideData = {} -- 隐藏 剧情
    local prequeldata = {} -- 简章 剧情
    for index, chapterId in pairs(self.Config.StoryChapterId) do
        local data = {}
        local storyChpterType = self.Config.StoryChpterType[index]
        if storyChpterType == XFubenConfigs.ChapterType.Prequel then
            local prequelChapter = XPrequelConfigs.GetPrequelChapterById(chapterId)
            data.ChapterName = prequelChapter.ChapterName
            tableInsert(prequeldata, data)
        elseif storyChpterType == XFubenConfigs.ChapterType.MainLine then
            local mainlineChapter = XDataCenter.FubenMainLineManager.GetChapterCfg(chapterId)
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(chapterId)
            data.ChapterName = XFubenMainLineConfigs.GetChapterMainChapterEn(chapterInfo.ChapterMainId)
            if mainlineChapter.Difficult == XDataCenter.FubenMainLineManager.DifficultHard then
                tableInsert(hideData, data)
            else
                tableInsert(nextData, data)
            end
        else
            if storyChpterType == XFubenConfigs.ChapterType.ShortStory then
                data.ChapterName = XFubenShortStoryChapterConfigs.GetChapterEnById(chapterId)
            elseif storyChpterType == XFubenConfigs.ChapterType.ExtralChapter then
                local extralChapter = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(chapterId)
                data.ChapterName = extralChapter.ChapterEn
            end
            tableInsert(nextData, data)
        end
    end
    
    return nextData, hideData, prequeldata
end

function XUiPanelStoryJump:GetShowData(info, title, showData)
    if XTool.IsTableEmpty(info) then
        return
    end
    local chapterName = ""
    local count = #info
    for index, data in pairs(info) do
        chapterName = string.format("%s%s", chapterName, data.ChapterName or "")
        if count > 1 and index < count and not string.IsNilOrEmpty(chapterName) then
            chapterName = string.format("%s、", chapterName)
        end
    end
    local tempData = { Title = title, Content = XUiHelper.GetText("UiFubenStoryJumpPopupContent", chapterName) }
    tableInsert(showData, tempData)
end

function XUiPanelStoryJump:GetNextChapterLocalKey(type, chapterId)
    if XPlayer.Id and type and chapterId then
        return string.format("NextChapterLocalData_%s_%s_%s", tostring(XPlayer.Id), tostring(type), tostring(chapterId))
    end
end

function XUiPanelStoryJump:GetNextChapterLocalData()
    local key = self:GetNextChapterLocalKey(self.Type, self.ChapterId)
    local isTip = XSaveTool.GetData(key) or 0
    return isTip == 1
end

function XUiPanelStoryJump:SaveNextChapterLocalData()
    local key = self:GetNextChapterLocalKey(self.Type, self.ChapterId)
    local isTip = XSaveTool.GetData(key) or 0
    if isTip == 1 then
        return
    end
    XSaveTool.SaveData(key, 1)
end

return XUiPanelStoryJump