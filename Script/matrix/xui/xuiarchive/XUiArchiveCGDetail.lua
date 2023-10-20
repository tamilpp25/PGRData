local XUiArchiveCGDetail = XLuaUiManager.Register(XLuaUi, "UiArchiveCGDetail")
local FirstIndex = 1

function XUiArchiveCGDetail:OnEnable()
    
end

function XUiArchiveCGDetail:OnStart(dataList, index, enableSpine)
    self.EnableSpine = enableSpine
    self:SetButtonCallBack()
    self:Init(dataList, index)
end

function XUiArchiveCGDetail:Init(dataList, index)
    local data = dataList and dataList[index]
    if data then
        self.Data = data
        self.DataList = dataList
        self.DataIndex = index
        self:SetMonsterData()
        self:CheckNextMonsterAndPreMonster()
        self._Control:ClearCGRedPointById(data:GetId())
    end
    self.BtnShowUI.gameObject:SetActiveEx(false)
    self.BtnHideUI.gameObject:SetActiveEx(true)
end

function XUiArchiveCGDetail:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnRight.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnLeft.CallBack = function()
        self:OnBtnLastClick()
    end
    self.BtnShowUI.CallBack = function()
        self:OnBtnShowUIClick()
    end
    self.BtnHideUI.CallBack = function()
        self:OnBtnHideUIClick()
    end
end

function XUiArchiveCGDetail:OnBtnBackClick()
    self:Close()
end

function XUiArchiveCGDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveCGDetail:SetMonsterData()
    local spineBg = self.Data:GetSpineBg()
    if self.EnableSpine and not string.IsNilOrEmpty(spineBg) then
        self.CGImage.gameObject:SetActiveEx(false)
        self.CGSpineRoot.gameObject:SetActiveEx(true)
        self.CGSpineRoot:LoadPrefab(spineBg)
    else
        self.CGSpineRoot.gameObject:SetActiveEx(false)
        self.CGImage.gameObject:SetActiveEx(true)
        if not string.IsNilOrEmpty(self.Data:GetBg()) then
            self.CGImage:SetRawImage(self.Data:GetBg())
        end
    end
    self.TitleText.text = self.Data:GetName()
    self.PainterText.text = self.Data:GetAuthor()
    self.TxtDesc.text = self.Data:GetDesc()
    local width = self.Data:GetBgWidth() ~= 0 and self.Data:GetBgWidth() or 1
    local high = self.Data:GetBgHigh() ~= 0 and self.Data:GetBgHigh() or 1
    self.CGImgAspect.aspectRatio = width / high
end

function XUiArchiveCGDetail:OnBtnNextClick()
    if self.NextIndex == 0 then
        return
    end
    self:Init(self.DataList, self.NextIndex)
end

function XUiArchiveCGDetail:OnBtnLastClick()
    if self.PreviousIndex == 0 then
        return
    end
    self:Init(self.DataList, self.PreviousIndex)
end

function XUiArchiveCGDetail:OnBtnShowUIClick()
    self.BtnShowUI.gameObject:SetActiveEx(false)
    self.BtnHideUI.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("ScreenShotEnable",function ()
            self:SetButtonHide(false)
            XLuaUiManager.SetMask(false)
        end)
end

function XUiArchiveCGDetail:OnBtnHideUIClick()
    self.BtnShowUI.gameObject:SetActiveEx(true)
    self.BtnHideUI.gameObject:SetActiveEx(false)
    self:SetButtonHide(true)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("ScreenShotDisable",function ()
            XLuaUiManager.SetMask(false)
        end)
end

function XUiArchiveCGDetail:CheckNextMonsterAndPreMonster()
    self.NextIndex = self:CheckNext(self.DataIndex + 1)
    self.PreviousIndex = self:CheckPrevious(self.DataIndex - 1)

    if self.NextIndex == 0 then
        self.NextIndex = self:CheckNext(FirstIndex)
    end

    if self.PreviousIndex == 0 then
        self.PreviousIndex = self:CheckPrevious(#self.DataList)
    end
end

function XUiArchiveCGDetail:SetButtonHide(IsHide)
    self.BtnBack.gameObject:SetActiveEx(not IsHide)
    self.BtnMainUi.gameObject:SetActiveEx(not IsHide)
    --self.BtnDown.gameObject:SetActiveEx(not IsHide)
    self.BtnLeft.gameObject:SetActiveEx(not IsHide)
    self.BtnRight.gameObject:SetActiveEx(not IsHide)
end

function XUiArchiveCGDetail:CheckNext(index)
    local next = 0
    for i = index , #self.DataList , 1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLock() then
            next = i
            break
        end
    end
    return next
end

function XUiArchiveCGDetail:CheckPrevious(index)
    local previous = 0
    for i = index , FirstIndex , -1 do
        local tmpData = self.DataList[i]
        if tmpData and not tmpData:GetIsLock() then
            previous = i
            break
        end
    end
    return previous
end