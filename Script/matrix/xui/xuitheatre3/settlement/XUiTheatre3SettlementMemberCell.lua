---@class XUiTheatre3SettlementMemberCell : XUiNode 成员
---@field Parent
---@field _Control XTheatre3Control
local XUiTheatre3SettlementMemberCell = XClass(XUiNode, "XUiTheatre3SettlementMemberCell")

function XUiTheatre3SettlementMemberCell:OnStart()

end

---只显示成员头像
function XUiTheatre3SettlementMemberCell:SetDataByMemberId(memberId)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterIcon = characterAgency:GetCharSmallHeadIcon(memberId)
    self.ImgRole:SetRawImage(characterIcon)

    self.ImgType.gameObject:SetActiveEx(true)
    self.PanelLv.gameObject:SetActiveEx(false)
    self.PanelExp.gameObject:SetActiveEx(false)
    self.PanelLvUp.gameObject:SetActiveEx(false)
end

---显示成员等级信息
---@param data XTheatre3Character
function XUiTheatre3SettlementMemberCell:SetData(data)
    self._CharacterId = data.CharacterId
    self._AddExp = data.ExpTemp
    self._BeforeLevel, self._BeforeExp, self._BeforeNeedExp = self._Control:CalculateCharacterLevel(data.CharacterId, data.Level, data.Exp, 0)
    self._NowLevel, self._NowExp, self._NowNeedExp = self._Control:CalculateCharacterLevel(data.CharacterId, data.Level, data.Exp, data.ExpTemp)
    
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterIcon = characterAgency:GetCharSmallHeadIcon(data.CharacterId)
    self.ImgRole:SetRawImage(characterIcon)

    self.ImgType.gameObject:SetActiveEx(false)
    self.PanelLv.gameObject:SetActiveEx(true)
    self.PanelExp.gameObject:SetActiveEx(true)

    if not XTool.IsNumberValid(self._AddExp) or self._IsAfterAnim then
        self:RefreshLv()
    else
        self.TxtLv.text = self._BeforeLevel
        self.ImgExp.fillAmount = self._BeforeExp / self._BeforeNeedExp
    end
end

function XUiTheatre3SettlementMemberCell:RefreshLv()
    self.TxtLv.text = self._NowLevel
    if self._NowNeedExp == 0 then
        self.ImgExp.fillAmount = 1
    else
        self.ImgExp.fillAmount = self._NowExp / self._NowNeedExp
    end
    self.PanelLvUp.gameObject:SetActiveEx(self._NowLevel > self._BeforeLevel)
end

--region Ui - ExpAnim
function XUiTheatre3SettlementMemberCell:PlayExpAnim()
    if self._IsEndPlayAnim then
        return
    end
    local curLv, curExp, curNeedExp = self._BeforeLevel, self._BeforeExp, self._BeforeNeedExp
    local animInterval = 10
    local animExpAdd = curNeedExp / XScheduleManager.SECOND * animInterval
    self:StopExpAnim()
    self._AnimTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopExpAnim()
            return
        end
        curExp = curExp + animExpAdd
        self.ImgExp.fillAmount = curExp / curNeedExp
        if curExp >= curNeedExp then
            curLv, curExp, curNeedExp = self._Control:CalculateCharacterLevel(self._CharacterId, curLv, curExp, 0)
            self.TxtLv.text = curLv
            self.PanelLvUp.gameObject:SetActiveEx(true)
            self.ImgExp.fillAmount = self._Control:CheckCharacterMaxLevel(self._CharacterId, curLv) and 1 or 0
        end
        
        if curLv >= self._NowLevel and curExp >= self._NowExp then
            self._IsEndPlayAnim = true
            self:StopExpAnim()
            self:RefreshLv()
        end
    end, animInterval)
end

function XUiTheatre3SettlementMemberCell:StopExpAnim()
    if self._AnimTimer then
        XScheduleManager.UnSchedule(self._AnimTimer)
        self._IsAfterAnim = true
        self._AnimTimer = nil
    end
end
--endregion

return XUiTheatre3SettlementMemberCell