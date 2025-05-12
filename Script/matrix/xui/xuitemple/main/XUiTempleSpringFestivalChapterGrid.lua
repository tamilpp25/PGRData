local XUiTempleSpringFestivalChapterStar = require("XUi/XUiTemple/Main/XUiTempleSpringFestivalChapterStar")

---@field _Control XTempleControl
---@class XUiTempleSpringFestivalChapterGrid:XUiNode
local XUiTempleSpringFestivalChapterGrid = XClass(XUiNode, "XUiTempleSpringFestivalChapterGrid")

function XUiTempleSpringFestivalChapterGrid:OnStart()
    self._Data = nil

    if self.GridStar1 then
        self.GridStar1.gameObject:SetActiveEx(false)
        self.GridStar2.gameObject:SetActiveEx(false)
        self.GridStar3.gameObject:SetActiveEx(false)
        ---@type XUiTempleSpringFestivalChapterStar
        self._Star1 = XUiTempleSpringFestivalChapterStar.New(self.GridStar1, self)
        ---@type XUiTempleSpringFestivalChapterStar
        self._Star2 = XUiTempleSpringFestivalChapterStar.New(self.GridStar2, self)
        ---@type XUiTempleSpringFestivalChapterStar
        self._Star3 = XUiTempleSpringFestivalChapterStar.New(self.GridStar3, self)
    end

    local button = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, button, self.OnClick)

    XUiHelper.RegisterClickEvent(self, self.BtnAbandon, self.OnClickAbandon)

    self._Timer = false

    self.ImgName = XUiHelper.TryGetComponent(self.Transform, "Normal/RImgChapter/ImgName", "Image")

    self.UiRed = XUiHelper.TryGetComponent(self.Transform, "Normal/Red", "Transform")
end

--function XUiTempleSpringFestivalChapterGrid:OnDisable()
--    self:StopTimer()
--end

---@param data XTempleUiControlStage
function XUiTempleSpringFestivalChapterGrid:Update(data)
    self._Data = data
    --self.TxtName.text = data.Name

    --self.RImgChapter
    if self.TxtName then
        self.TxtName:SetSprite(data.ImageNumber)
    end

    if self.UiRed then
        self.UiRed.gameObject:SetActiveEx(data.IsShowRed)
    end

    --self.ImgMask.gameObject:SetActiveEx(data.IsShowMask)
    self.BtnAbandon.gameObject:SetActiveEx(data.IsShowContinue)
    self.PanelLock.gameObject:SetActiveEx(data.IsShowLock)
    self.PanelOngoing.gameObject:SetActiveEx(data.IsShowContinue)
    if self.OnGoing2 then
        self.OnGoing2.gameObject:SetActiveEx(data.IsShowContinue)
    end
    if data.IsShowLock then
        self.Normal.gameObject:SetActiveEx(false)
    else
        self.Normal.gameObject:SetActiveEx(true)
    end

    if data.IsShowLock then
        self.RImgChapter.gameObject:SetActiveEx(false)
    else
        self.RImgChapter.gameObject:SetActiveEx(true)
    end

    if self._Control:IsCoupleChapter() then
        self._Star1:Close()
        self._Star2:Close()
        self._Star3:Close()
    else
        if self._Star1 then
            if not data.IsShowLock then
                if data.IsHideStar then
                    self._Star1:Close()
                    self._Star2:Close()
                    self._Star3:Close()
                else
                    self._Star1:Open()
                    self._Star2:Open()
                    self._Star3:Open()
                    self._Star1:Update(data.StarAmount >= 1)
                    self._Star2:Update(data.StarAmount >= 2)
                    self._Star3:Update(data.StarAmount >= 3)
                end
            else
                self._Star1:Close()
                self._Star2:Close()
                self._Star3:Close()
            end
        end
    end
end

function XUiTempleSpringFestivalChapterGrid:OnClick()
    if self._Data then
        self._Control:GetUiControl():OnClickStage(self._Data.StageId)
        self.UiRed.gameObject:SetActiveEx(false)
    end
end

function XUiTempleSpringFestivalChapterGrid:OnClickAbandon()
    self._Control:GetUiControl():OnClickAbandon()
end

--function XUiTempleSpringFestivalChapterGrid:StartTimer()
--    self._Timer = XScheduleManager.ScheduleForever(function()
--        self:UpdateUnlockTime()
--    end, XScheduleManager.SECOND)
--end

--function XUiTempleSpringFestivalChapterGrid:StopTimer()
--    if self._Timer then
--        XScheduleManager.UnSchedule(self._Timer)
--        self._Timer = nil
--    end
--end

--function XUiTempleSpringFestivalChapterGrid:UpdateUnlockTime()
--    if self._Data.IsShowLock then
--        local text = self._Control:GetUiControl():GetTextTimeUnlock(self._Data.StageId)
--        if not text then
--            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_STAGE)
--            return
--        end
--        --self.TextLock.text = text
--    end
--end

return XUiTempleSpringFestivalChapterGrid
