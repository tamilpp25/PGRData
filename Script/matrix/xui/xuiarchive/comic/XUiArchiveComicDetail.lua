--- 漫画图鉴漫画浏览界面
---@class XUiArchiveComicDetail: XLuaUi
---@field private _Control XArchiveControl
local XUiArchiveComicDetail = XLuaUiManager.Register(XLuaUi, 'UiArchiveComicDetail')

function XUiArchiveComicDetail:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self:RegisterClickEvent(self.BtnRight, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLastClick)
    self:RegisterClickEvent(self.BtnShowUI, self.OnBtnShowUIClick)
    self:RegisterClickEvent(self.BtnHideUI, self.OnBtnHideUIClick)
end

function XUiArchiveComicDetail:OnStart(chapterCfg, enableSpine)
    self.EnableSpine = enableSpine
    ---@type XTableArchiveComicChapter
    self.ChapterCfg = chapterCfg
    
    self:Init()
end

function XUiArchiveComicDetail:OnEnable()
    self:ShowComic(self.CurDetailId)
end

function XUiArchiveComicDetail:Init()
    if self.ChapterCfg then
        -- 初始化漫画显示
        self.IsComicValid = XTool.IsNumberValid(self.ChapterCfg.DetailCount > 0)
        self.CurIndex = 1
        self.CurDetailId = self.IsComicValid and self.ChapterCfg.Id * 10000 + 1 or 0
        
        -- 消除对应的红点
        self._Control.ComicControl:ClearComicChapterRedShow(self.ChapterCfg.Id)
    end
    self.BtnShowUI.gameObject:SetActiveEx(false)
    self.BtnHideUI.gameObject:SetActiveEx(true)
end

function XUiArchiveComicDetail:SetButtonHide(IsHide)
    self.BtnBack.gameObject:SetActiveEx(not IsHide)
    self.BtnMainUi.gameObject:SetActiveEx(not IsHide)
    self.BtnLeft.gameObject:SetActiveEx(not IsHide)
    self.BtnRight.gameObject:SetActiveEx(not IsHide)
end

function XUiArchiveComicDetail:ShowComic(id)
    if XTool.IsNumberValid(id) then
        ---@type XTableArchiveComicDetail
        local detailCfg = self._Control.ComicControl:GetComicDetailCfgById(id)

        if detailCfg then
            self.CGSpineRoot.gameObject:SetActiveEx(false)
            self.CGImage.gameObject:SetActiveEx(true)
            
            if not string.IsNilOrEmpty(detailCfg.Bg) then
                self.CGImage:SetRawImage(detailCfg.Bg)
            end
            
            local width = detailCfg.BgWidth ~= 0 and detailCfg.BgWidth or 1
            local high = detailCfg.BgHigh ~= 0 and detailCfg.BgHigh or 1
            self.CGImgAspect.aspectRatio = width / high
        end
    end

    self.BtnRight:SetButtonState(self.CurIndex < self.ChapterCfg.DetailCount and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnLeft:SetButtonState(self.CurIndex > 1 and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

--region 事件回调
function XUiArchiveComicDetail:OnBtnNextClick()
    if not self.IsComicValid then
        return
    end

    if self.CurIndex < self.ChapterCfg.DetailCount then
        self.CurIndex = self.CurIndex + 1
        self.CurDetailId = self.ChapterCfg.Id * 10000 + self.CurIndex
        
        self:ShowComic(self.CurDetailId)
    end
end

function XUiArchiveComicDetail:OnBtnLastClick()
    if not self.IsComicValid then
        return
    end

    if self.CurIndex > 1 then
        self.CurIndex = self.CurIndex - 1
        self.CurDetailId = self.ChapterCfg.Id * 10000 + self.CurIndex

        self:ShowComic(self.CurDetailId)
    end
end

function XUiArchiveComicDetail:OnBtnShowUIClick()
    self.BtnShowUI.gameObject:SetActiveEx(false)
    self.BtnHideUI.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("ScreenShotEnable",function ()
        self:SetButtonHide(false)
        XLuaUiManager.SetMask(false)
    end)
end

function XUiArchiveComicDetail:OnBtnHideUIClick()
    self.BtnShowUI.gameObject:SetActiveEx(true)
    self.BtnHideUI.gameObject:SetActiveEx(false)
    self:SetButtonHide(true)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("ScreenShotDisable",function ()
        XLuaUiManager.SetMask(false)
    end)
end
--endregion

return XUiArchiveComicDetail