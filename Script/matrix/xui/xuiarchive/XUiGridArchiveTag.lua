local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
local XUiGridArchiveTag = XClass(XUiNode, "XUiGridArchiveTag")
local tableInsert = table.insert
local Select = CS.UiButtonState.Select
local Normal = CS.UiButtonState.Normal

function XUiGridArchiveTag:OnStart()
    self:SetButtonCallBack()
end

function XUiGridArchiveTag:SetButtonCallBack()
    self.BtnTagItem.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridArchiveTag:OnBtnSelect()
    if self.BtnTagItem.ButtonState ~= Select then
        for index, tagId in pairs(self.Base.TagIds) do
            if self.Data.Id == tagId then
                self.Base.TagIds[index] = nil
            end
        end
    else

        local count = 0
        for _, _ in pairs(self.Base.TagIds) do
            count = count + 1
        end
        if count < 3 then
            tableInsert(self.Base.TagIds, self.Data.Id)
        else
            XUiManager.TipText("ArchiveTagMaxText")
            self.BtnTagItem:SetButtonState(Normal)
        end
    end
end

function XUiGridArchiveTag:UpdateGrid(chapter, parent)
    self.Base = parent
    self.Data = chapter
    self:SetTag(chapter)
end

function XUiGridArchiveTag:SetTag(chapter)
    local archiveTagCfg = self._Control:GetArchiveTagCfgById(chapter.Id)
    
    self.TxtTag.text = archiveTagCfg.Name
    self.TxtTag.color = XUiHelper.Hexcolor2Color(archiveTagCfg.Color)
    local bgImg = archiveTagCfg.Bg
    if bgImg then self.Base:SetUiSprite(self.Bg, bgImg) end
    for _, tagId in pairs(self.Base.TagIds) do
        if chapter.Id == tagId then
            self.BtnTagItem:SetButtonState(Select)
        end
    end

end


return XUiGridArchiveTag