---@class XUiGridGame2048Buff: XUiNode
---@field _Control XGame2048Control
---@field _GameControl XGame2048GameControl
local XUiGridGame2048Buff = XClass(XUiNode, 'XUiGridGame2048Buff')

function XUiGridGame2048Buff:OnStart()
    self._GameControl = self._Control:GetGameControl()
    self.GridBtn.CallBack = handler(self, self.OnBtnClickEvent)
end

function XUiGridGame2048Buff:InitData(buffId, initCharge)
    self._BuffId = buffId
    self._InitCharge = initCharge
    
    self.GridBtn:SetRawImage(self._Control:GetBuffIcon(self._BuffId))
    self._IsTriggerOnce = self._Control:GetBuffIsTriggerOnce(self._BuffId)
    self._HadTrigger = false
    self.TxtNum.text = ''
    self.TxtNum.transform.parent.gameObject:SetActiveEx(true)
    self:RefreshaBuffStatus()
    
    self:InitTheme()
end

function XUiGridGame2048Buff:InitTheme()
    -- 设置cd颜色
    local curChapterId = self._Control:GetCurChapterId()
    local cdBgColor = self._Control:GetChapterBuffCdBgColorById(curChapterId)
    local cdNumColor = self._Control:GetChapterBuffCdNumColorById(curChapterId)

    if not string.IsNilOrEmpty(cdBgColor) then
        self.ImgNumBg.color = XUiHelper.Hexcolor2Color(string.gsub(cdBgColor, '#', ''))
    end

    if not string.IsNilOrEmpty(cdNumColor) then
        self.TxtNum.color = XUiHelper.Hexcolor2Color(string.gsub(cdNumColor, '#', ''))
    end
end

function XUiGridGame2048Buff:RefreshaBuffStatus()
    local stepInterval = self._Control:GetBuffCD(self._BuffId)
    local curSteps = self._GameControl.TurnControl:GetCurStepsCount()

    if (curSteps + self._InitCharge) >= stepInterval then
        self._HadTrigger = true
    end

    if self._HadTrigger and self._IsTriggerOnce then
        self.TxtNum.text = ''
        self.TxtNum.transform.parent.gameObject:SetActiveEx(false)
    else
        curSteps = (curSteps + self._InitCharge) % stepInterval
        self.TxtNum.text = stepInterval - curSteps
    end
end

function XUiGridGame2048Buff:OnBtnClickEvent()
    self.Parent:ShowBuffDetail(self._BuffId, self)
end

return XUiGridGame2048Buff