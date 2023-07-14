local XUiArchiveStoryDialog = XLuaUiManager.Register(XLuaUi, "UiArchiveStoryDialog")
local CSTextManagerGetText = CS.XTextManager.GetText
local OneStory = 1
local TwoStory = 2

function XUiArchiveStoryDialog:OnEnable()

end

function XUiArchiveStoryDialog:OnStart(data)
    self.Data = data
    self:Init()
    self:SetButtonCallBack()
end

function XUiArchiveStoryDialog:Init()
    local title = self.Data:GetName()
    if self.Data:GetSubName() then
        local tmpText = string.gsub(self.Data:GetSubName(), "_", "-")
        title = string.format("%s%s",tmpText,self.Data:GetName())
    end
    self.TxtStoryDec.text = title
    self.TxtStoryName.text = self.Data:GetDesc()
    self.PlayType = #self.Data:GetStoryId()
    if self.PlayType == TwoStory then
        self.BtnEnterStoryBefore.gameObject:SetActiveEx(true)
        self.BtnEnterStoryAfter.gameObject:SetActiveEx(true)

        self.BtnEnterStoryBefore:SetName(CSTextManagerGetText("PlayBeforeStory"))
        self.BtnEnterStoryAfter:SetName(CSTextManagerGetText("PlayAfterStory"))
    elseif self.PlayType == OneStory then
        self.BtnEnterStoryBefore.gameObject:SetActiveEx(true)
        self.BtnEnterStoryAfter.gameObject:SetActiveEx(false)

        self.BtnEnterStoryBefore:SetName(CSTextManagerGetText("PlayStory"))
    else
        self.BtnEnterStoryBefore.gameObject:SetActiveEx(false)
        self.BtnEnterStoryAfter.gameObject:SetActiveEx(false)
    end
end

function XUiArchiveStoryDialog:SetButtonCallBack()
    self.BtnMask.CallBack = function()
        self:OnBtnBackClick()
    end

    if self.PlayType == TwoStory then
        self.BtnEnterStoryBefore.CallBack = function()
            self:OnBtnPlayClick(1)
        end
        self.BtnEnterStoryAfter.CallBack = function()
            self:OnBtnPlayClick(2)
        end

    elseif self.PlayType == OneStory then
        self.BtnEnterStoryBefore.CallBack = function()
            self:OnBtnPlayClick(1)
        end
    end
end

function XUiArchiveStoryDialog:OnBtnBackClick()
    self:Close()
end

function XUiArchiveStoryDialog:OnBtnPlayClick(index)
    XDataCenter.MovieManager.PlayMovie(self.Data:GetStoryId(index))
end


