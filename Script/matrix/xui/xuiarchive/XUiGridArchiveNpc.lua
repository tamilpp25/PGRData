local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveNpc = XClass(XUiNode, "XUiGridArchiveNpc")

local ShortSettingMax = 5
local LongSettingMax = 5

local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")

local TweenSpeed = {
    High = 0.15,
    Mid = 0.2,
    Low = 0.5,
}

function XUiGridArchiveNpc:OnStart()
    self:SetButtonCallBack()
    self:SetGridAnimeData()
    self.ShortSettingItem = {}
    self.LongSettingItem = {}
    self:SetStartPos()
    self:SetStartScale()
    self:SetEndAlpha()
    self:SetDetailStartAlpha()
end

function XUiGridArchiveNpc:SetButtonCallBack()
    self.ArchiveNpcBtn.CallBack = function()
        self:OnBtnSelect()
    end
    self.ArchiveNpcCloseBtn.CallBack = function()
        self:OnBtnUnSelect()
    end
end

function XUiGridArchiveNpc:OnBtnSelect()
    if self.Chapter:GetIsLock() then
        XUiManager.TipError(self.Chapter:GetLockDesc())
        return
    end
    self.Base:SelectNpc(self.CurIndex)
end

function XUiGridArchiveNpc:OnBtnUnSelect()
    self.Base:SelectNpc(#self.Base.PageDatas + 1)
    --self.Base:UnSelectNpc()
end

function XUiGridArchiveNpc:UpdateGrid(chapter, base, index)
    self.Chapter = chapter
    self:SetNpcData(chapter)
    self:SetNpcDetailData(chapter)
    self.Base = base
    self.CurIndex = index
end

function XUiGridArchiveNpc:SetNpcData(chapter)
    self.NpcData = {}
    self.NpcData.GameObject = self.NpcItem.gameObject
    self.NpcData.Transform = self.NpcItem.transform
    XTool.InitUiObject(self.NpcData)
    self.NpcData.ArchiveNpcName.text = chapter:GetIsLock() and LockNameText or chapter:GetName()
    self.NpcData.NPCImg.gameObject:SetActiveEx(not chapter:GetIsLock())
    self.NpcData.NPCLockImg.gameObject:SetActiveEx(chapter:GetIsLock())
    self.NpcData.NPCImg:SetRawImage(chapter:GetPicSmall())
    self.NpcData.NPCLockImg:SetRawImage(chapter:GetPicSmall())
end

function XUiGridArchiveNpc:SetNpcDetailData(chapter)
    self.NpcDetailData = {}
    self.NpcDetailData.GameObject = self.NpcItemDaily.gameObject
    self.NpcDetailData.Transform = self.NpcItemDaily.transform
    XTool.InitUiObject(self.NpcDetailData)
    self.NpcDetailData.NpcName.text = chapter:GetName()
    self.NpcDetailData.NPCImg:SetRawImage(chapter:GetPicBig())
    self.NpcDetailData.ShortSettingObjs = {self.NpcDetailData.DailyItem1,
        self.NpcDetailData.DailyItem2,
        self.NpcDetailData.DailyItem3,
        self.NpcDetailData.DailyItem4,
        self.NpcDetailData.DailyItem5,
    }
    self.NpcDetailData.LongSettingObjs = {self.NpcDetailData.StoryText1,
        self.NpcDetailData.StoryText2,
        self.NpcDetailData.StoryText3,
        self.NpcDetailData.StoryText4,
        self.NpcDetailData.StoryText5,
    }

    self:SetNpcShortSetting()
    self:SetNpcLongSetting()
end

function XUiGridArchiveNpc:SetNpcShortSetting()
    local shortSettingList = self._Control:GetArchiveStoryNpcSettingList(self.Chapter:GetId(),XEnumConst.Archive.SettingType.Setting)
    for index = 1,ShortSettingMax do
        local setting = shortSettingList[index]
        if setting then
            local item = self.ShortSettingItem[index]
            if not item then
                item = {}
                item.Transform = self.NpcDetailData.ShortSettingObjs[index].transform
                item.GameObject = self.NpcDetailData.ShortSettingObjs[index].gameObject
                XTool.InitUiObject(item)
                self.ShortSettingItem[index] = item
            end

            item.SettingTitle.text = setting:GetTitle()
            if setting:GetIsLock() then
                item.SettingText.text = setting:GetLockDesc()
            else
                item.SettingText.text = setting:GetText()
            end
        end
        self.NpcDetailData.ShortSettingObjs[index].gameObject:SetActiveEx(setting and true or false)
    end
end

function XUiGridArchiveNpc:SetNpcLongSetting()
    local longSettingList = self._Control:GetArchiveStoryNpcSettingList(self.Chapter:GetId(),XEnumConst.Archive.SettingType.Story)
    for index = 1, LongSettingMax do
        local setting = longSettingList[index]
        if setting then
            local item = self.LongSettingItem[index]
            if not item then
                item = {}
                item.Transform = self.NpcDetailData.LongSettingObjs[index].transform
                item.GameObject = self.NpcDetailData.LongSettingObjs[index].gameObject
                XTool.InitUiObject(item)
                self.LongSettingItem[index] = item
            end

            item.StoryTitle.text = setting:GetTitle()
            if setting:GetIsLock() then
                item.StoryText.text = setting:GetLockDesc()
            else
                item.StoryText.text = setting:GetText()
            end
        end
        self.NpcDetailData.LongSettingObjs[index].gameObject:SetActiveEx(setting and true or false)
    end
end

function XUiGridArchiveNpc:SetGridAnimeData()
    local delta = self.NpcItemDaily.rect.width - self.NpcItem.rect.width

    self.StartPos = self.NpcItem.transform.localPosition
    self.LeftEndPos = self.NpcItem.transform.localPosition - CS.UnityEngine.Vector3(delta / 2, 0, 0)
    self.RightEndPos = self.NpcItem.transform.localPosition + CS.UnityEngine.Vector3(delta / 2, 0, 0)

    self.StartAlpha = 0
    self.EndAlpha = 1

    self.StartScale = CS.UnityEngine.Vector3(1.2,1.2,1)
    self.EndScale = CS.UnityEngine.Vector3(1,1,1)
end

function XUiGridArchiveNpc:SetStartPos()
    self.NpcItem.localPosition = self.StartPos
end
function XUiGridArchiveNpc:SetLeftEndPos()
    self.NpcItem.localPosition = self.LeftEndPos
end
function XUiGridArchiveNpc:SetRightEndPos()
    self.NpcItem.localPosition = self.RightEndPos
end

function XUiGridArchiveNpc:SetStartScale()
    self.NpcItemDaily.localScale = self.StartScale
    self.NpcItemDaily.gameObject:SetActiveEx(false)
end
function XUiGridArchiveNpc:SetEndScale()
    self.NpcItemDaily.localScale = self.EndScale
    self.NpcItemDaily.gameObject:SetActiveEx(true)
end

function XUiGridArchiveNpc:SetDetailStartAlpha()
    self.NpcItemDailyCanvasGroup.alpha = self.StartAlpha
end
function XUiGridArchiveNpc:SetDetailEndAlpha()
    self.NpcItemDailyCanvasGroup.alpha = self.EndAlpha
end

function XUiGridArchiveNpc:SetStartAlpha()
    self.NpcItemCanvasGroup.alpha = self.StartAlpha
end
function XUiGridArchiveNpc:SetEndAlpha()
    self.NpcItemCanvasGroup.alpha = self.EndAlpha
end

function XUiGridArchiveNpc:SetItemEnable(cb)
    self.NpcItemCanvasGroupAlphaTimer = XUiHelper.DoAlpha(self.NpcItemCanvasGroup, self.StartAlpha, self.EndAlpha, TweenSpeed.Low, XUiHelper.EaseType.Sin, cb)
end
function XUiGridArchiveNpc:SetItemDisable(cb)
    self.NpcItemCanvasGroupAlphaTimer = XUiHelper.DoAlpha(self.NpcItemCanvasGroup, self.EndAlpha, self.StartAlpha, TweenSpeed.High, XUiHelper.EaseType.Sin, cb)
end
function XUiGridArchiveNpc:SetItemDailyEnable(cb)
    self.NpcItemDailyCanvasGroupAlphaTimer = XUiHelper.DoAlpha(self.NpcItemDailyCanvasGroup, self.StartAlpha, self.EndAlpha, TweenSpeed.Mid, XUiHelper.EaseType.Sin, nil)
    self.NpcItemDailyScaleTimer = XUiHelper.DoScale(self.NpcItemDaily,self.StartScale , self.EndScale, TweenSpeed.Mid, XUiHelper.EaseType.Sin, cb)
    XScheduleManager.ScheduleOnce(function ()
            self.NpcItemDaily.gameObject:SetActiveEx(true)
        end, 1)
end
function XUiGridArchiveNpc:SetItemDailyDisable(cb)
    self.NpcItemDailyCanvasGroupAlphaTimer = XUiHelper.DoAlpha(self.NpcItemDailyCanvasGroup, self.EndAlpha, self.StartAlpha, TweenSpeed.Mid, XUiHelper.EaseType.Sin, nil)
    self.NpcItemDailyScaleTimer = XUiHelper.DoScale(self.NpcItemDaily, self.EndScale, self.StartScale, TweenSpeed.Mid, XUiHelper.EaseType.Sin, function ()
            self.NpcItemDaily.gameObject:SetActiveEx(false)
            if cb then cb() end
        end)
end
function XUiGridArchiveNpc:GoLeft(cb)
    self.NpcItemMoveTimer = XUiHelper.DoMove(self.NpcItem, self.LeftEndPos, TweenSpeed.High, XUiHelper.EaseType.Sin, cb)
end
function XUiGridArchiveNpc:GoRight(cb)
    self.NpcItemMoveTimer = XUiHelper.DoMove(self.NpcItem, self.RightEndPos, TweenSpeed.High, XUiHelper.EaseType.Sin, cb)
end
function XUiGridArchiveNpc:GoBack(cb,IsMove)
    self.NpcItemMoveTimer = XUiHelper.DoMove(self.NpcItem, self.StartPos, IsMove and TweenSpeed.High or 0, XUiHelper.EaseType.Sin, cb)
end
function XUiGridArchiveNpc:StopTween()
    if self.NpcItemMoveTimer then
        XScheduleManager.UnSchedule(self.NpcItemMoveTimer)
    end
    if self.NpcItemDailyScaleTimer then
        XScheduleManager.UnSchedule(self.NpcItemDailyScaleTimer)
    end
    if self.NpcItemDailyCanvasGroupAlphaTimer then
        XScheduleManager.UnSchedule(self.NpcItemDailyCanvasGroupAlphaTimer)
    end
    if self.NpcItemCanvasGroupAlphaTimer then
        XScheduleManager.UnSchedule(self.NpcItemCanvasGroupAlphaTimer)
    end

end


return XUiGridArchiveNpc