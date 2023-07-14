-- Grid - 效果描述
--===============================================================================
local XGridEffect  = XClass(nil, "XGridEffect")

function XGridEffect:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XGridEffect:Refresh(effectId)
    self.TxtBuffName.text = XColorTableConfigs.GetEffectName(effectId)
    self.TxtBuffDetails.text = XColorTableConfigs.GetEffectShowDesc(effectId)
    self.RImgBuffIcon:SetRawImage(XColorTableConfigs.GetEffectIcon(effectId))
    self:SetActive(true)
end

function XGridEffect:SetActive(active)
    self.GameObject:SetActiveEx(active)
end

--===============================================================================



local LimitPaddingV = 50     -- 弹窗与边界的垂直偏移限制
local LimitPaddingH = 25     -- 弹窗与边界的水平偏移限制
local PointPadding = 50     -- 弹窗与点位的水平偏移限制
-- 点位操作弹窗
local XPanelMapPointTip = XClass(nil, "XPanelMapPointTip")

function XPanelMapPointTip:Ctor(root, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root

    self.MoveCost = nil
    self.DoAcionPointCost = nil
    self.DoStudyDataCost = nil
    self.DoSpecialAcionPointCost = nil
    self.DoSpecialStudyDataCost = nil
    self.PointObj = nil
    self.GridEffects = {}

    self._GameManager = XDataCenter.ColorTableManager.GetGameManager()
    self._GameData = self._GameManager:GetGameData()
    self:SetNothingDoCount(1)

    XTool.InitUiObject(self)

    self.GameObject:SetActive(false)
    self:_AddBtnListener()
end



-- public
------------------------------------------------------------------

function XPanelMapPointTip:SetData(data, pointObj)
    self.PointObj = pointObj
    if not XTool.IsTableEmpty(data) then
        self.MoveCost = data.Cost
        self.DoAcionPointCost = data.NormalExeCost
        self.DoStudyDataCost = data.NormalExeCostData
        self.DoSpecialAcionPointCost = data.SpecialExeCost
        self.DoSpecialStudyDataCost = data.SpecialExeCostData

        self.NoramlExeCode = data.NormalExeCode
        self.SpecialExeCode = data.SpecialExeCode
    else    -- data为空则玩家就在该点，消耗默认读配置
        local params = pointObj:GetPointParams()
        local type = pointObj:GetType()
        local colorType = pointObj:GetColorType()

        self.MoveCost = 0
        if type == XColorTableConfigs.PointType.Lab then
            self.DoStudyDataCost = params[2]
        else
            self.DoStudyDataCost = 0
        end
        if type == XColorTableConfigs.PointType.Hospital then
            self.DoAcionPointCost = self._GameData:CheckIsStudyLevelMax(colorType) and params[3] or params[1]
            self.DoSpecialAcionPointCost = self._GameData:CheckIsStudyLevelMax(colorType) and params[4] or params[1]
            self.DoSpecialStudyDataCost = self._GameData:CheckIsStudyLevelMax(colorType) and 0 or params[2]
        else
            self.DoAcionPointCost = params[1]
            self.DoSpecialAcionPointCost = 0
            self.DoSpecialStudyDataCost = 0
        end

        self.NoramlExeCode = nil
        self.SpecialExeCode = nil
    end
end

function XPanelMapPointTip:Refresh()
    self:_RefreshBtn()
    self:_RefreshBuff()
    self:_RefreshInfo()
    self.GameObject:SetActive(true)
end

-- 更新弹窗位置
function XPanelMapPointTip:UpdatePosition(pointPosition)
    self.Transform.position = pointPosition
    local XLimit = self.Transform.parent.rect.width / 2
    local YLimit = self.Transform.parent.rect.height / 2
    -- 由于Ui预制体布局不同，需要计算偏移
    local verticalOffect = self.Transform.position.x - self.Bg.transform.position.x
    local horizontalOffect = self.Transform.position.y - self.Bg.transform.position.y
    local objWidth

    -- 有作用效果时要显示效果面板
    local effectIds = self._GameManager:GetPointEffectList(self.PointObj:GetType(), self.PointObj:GetColorType())
    if XTool.IsTableEmpty(effectIds) then
        objWidth = self.Bg.transform.rect.width
    else
        objWidth = self.Bg.transform.rect.width + self.BgBuff.transform.rect.width
        verticalOffect = 0
    end

    local objHeight = self.Transform.rect.height
    local x, y
    if self.Transform.localPosition.x + XLimit - (PointPadding + LimitPaddingH + objWidth) >= 0 then
        x = self.Transform.localPosition.x - PointPadding - objWidth / 2
    else
        x = self.Transform.localPosition.x + PointPadding + objWidth / 2
    end

    if self.Transform.localPosition.y - objHeight / 2 >= 0 then
        y = self.Transform.localPosition.y - objHeight / 2
    else
        local MaxOffset = (YLimit - objHeight / 2 - LimitPaddingV > 0) and (YLimit - objHeight / 2 - LimitPaddingV) or 0
        if self.Transform.localPosition.y >= 0 then
            y =  math.min(self.Transform.localPosition.y, MaxOffset)
        else
            y =  math.max(self.Transform.localPosition.y, -MaxOffset)
        end
    end
    self.Transform.localPosition = Vector3(x, y, self.Transform.localPosition.z)
    self.Transform.position = self.Transform.position + Vector3(verticalOffect, horizontalOffect, 0)
end

-- 判断当前打开的弹窗是否一致
function XPanelMapPointTip:IsSamePoint(pointObj)
    return self.PointObj == pointObj
end

-- 设置本次打开弹窗但不操作的计数
function XPanelMapPointTip:SetNothingDoCount(value)
    self.NothingDoCount = value
end

function XPanelMapPointTip:GetNothingDoCount()
    return self.NothingDoCount
end

------------------------------------------------------------------



-- private
------------------------------------------------------------------

-- 刷新基础信息
function XPanelMapPointTip:_RefreshInfo()
    self.TxtTitle.text = self.PointObj:GetName()
    self.TxtMessage.text = self.PointObj:GetPointDesc()
    self.TxtInfoDetails.text = self.PointObj:GetEffectDesc()
    self.RImgIcon:SetRawImage(self.PointObj:GetTipIcon())
    if self.PointObj:GetType() == XColorTableConfigs.PointType.Lab then
        self.TxtLv.text = XUiHelper.GetText("ColorTableLvTxt", self._GameData:GetStudyLevels(self.PointObj:GetColorType()))
    elseif self.PointObj:GetType() == XColorTableConfigs.PointType.Boss then
        self.TxtLv = self.Transform:Find("TxtTitle/TxtLv"):GetComponent("Text")
        self.TxtLv.text = XUiHelper.GetText("ColorTableLvTxt", self._GameData:GetBossLevels(self.PointObj:GetColorType()))
    elseif self.PointObj:GetType() == XColorTableConfigs.PointType.Tower then
        self.TxtLv.gameObject:SetActiveEx(false)
    elseif self.PointObj:GetType() == XColorTableConfigs.PointType.HideBoss then
        self.TxtLv = self.Transform:Find("TxtTitle/TxtLv"):GetComponent("Text")
        if self.TxtLv then self.TxtLv.gameObject:SetActiveEx(false) end
    end
end

-- 刷新按钮面板
function XPanelMapPointTip:_RefreshBtn()
    -- 阶段二不需要显示按钮及提示
    if self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.Fight then
        if self.TxtTips then self.TxtTips.gameObject:SetActive(false) end
        if self.TxtBg then self.TxtBg.gameObject:SetActive(false) end
        if self.BtnGo then self.BtnGo.gameObject:SetActive(false) end
        if self.BtnDo then self.BtnDo.gameObject:SetActive(false) end
        if self.PanelBtn then self.PanelBtn.gameObject:SetActive(false) end
        if self.PanelBtn2 then self.PanelBtn2.gameObject:SetActive(false) end
        return
    end

    local pointType = self.PointObj:GetType()
    local positonId = self.PointObj:GetPositionId()
    local curPostionId = self._GameData:GetCurPosition()
    local colorType = self.PointObj:GetColorType()

    if self.PanelBtn then self.PanelBtn.gameObject:SetActive(true) end
    if self.PanelBtn2 then
        self.PanelBtn2.gameObject:SetActive(pointType == XColorTableConfigs.PointType.Hospital)
    end
    if self.BtnKill then self.BtnKill.gameObject:SetActive(false) end
    if self.BtnGo then
        self:_RefreshBtnCost(self.BtnGo, positonId ~= curPostionId, colorType, self.MoveCost, self.DoStudyDataCost)
    end

    if pointType == XColorTableConfigs.PointType.Boss or pointType == XColorTableConfigs.PointType.HideBoss then
        self.TxtTips.gameObject:SetActive(self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.PlayGame)
        self.BtnDo.gameObject:SetActive(self._GameData:GetCurStage() == XColorTableConfigs.CurStageType.Fight)
    elseif pointType == XColorTableConfigs.PointType.Tower then
        self.BtnDo.gameObject:SetActive(false)
    elseif pointType == XColorTableConfigs.PointType.Hospital then
        local canDo, canDSpecial, canKill, canCure = self._GameManager:GetPointActionState(pointType, colorType)
        -- boss被根除需要隐藏
        self.PanelBtn2.gameObject:SetActive(canDSpecial or canKill)
        self:_RefreshBtnCost(self.BtnDSpecial,
            canDSpecial and not self._GameData:CheckBossIsKill(colorType),
            colorType,
            self.DoSpecialAcionPointCost + self.MoveCost,
            self.DoSpecialStudyDataCost)
        self:_RefreshBtnCost(self.BtnCure,
            canKill and not self._GameData:CheckBossIsKill(colorType),
            colorType,
            self.DoAcionPointCost + self.MoveCost,
            self.DoStudyDataCost)
        self:_RefreshBtnCost(self.BtnDo,
            (canDo or canCure) and not self._GameData:CheckBossIsKill(colorType),
            colorType,
            self.DoAcionPointCost + self.MoveCost,
            self.DoStudyDataCost)
    elseif pointType == XColorTableConfigs.PointType.Lab then
        self:_RefreshBtnCost(self.BtnDo, not self._GameData:CheckIsStudyLevelMax(colorType), colorType, self.DoAcionPointCost + self.MoveCost, self.DoStudyDataCost)
    else
        self:_RefreshBtnCost(self.BtnDo, true, colorType, self.DoAcionPointCost + self.MoveCost, self.DoStudyDataCost)
    end
end

-- 刷新Btn消耗
function XPanelMapPointTip:_RefreshBtnCost(btn, active, colorType, actionCost, dataCost)
    btn.gameObject:SetActive(active)
    -- 行动力消耗
    btn:SetNameByGroup(1, self:_GetAcitonCostText(actionCost))
    -- 数据消耗
    if XTool.IsNumberValid(dataCost) then
        btn:SetNameByGroup(2, self:_GetStudyDataCostText(dataCost))
        btn:SetRawImage(XColorTableConfigs.GetStudyDataCostIcon(colorType))
    end
    -- 数据消耗图标显示
    if btn.RawImageList.Count > 0 then
        for i = 0, btn.RawImageList.Count - 1, 1 do
            btn.RawImageList[i].gameObject:SetActiveEx(XTool.IsNumberValid(dataCost))
        end
    end
    -- 数据消耗文本显示
    if btn.TxtGroupList.Count >= 3 then
        for i = 0, btn.TxtGroupList[2].TxtList.Count - 1, 1 do
            btn.TxtGroupList[2].TxtList[i].gameObject:SetActiveEx(XTool.IsNumberValid(dataCost))
        end
    end
end


function XPanelMapPointTip:_GetAcitonCostText(cost)
    local curActionPoint = self._GameData:GetActionPoint()
    return curActionPoint >= cost and cost or XUiHelper.GetText("ColorTableNoEnoughCostTxt", cost)
end

-- 设置消耗，不够资源时改变消耗数字颜色
function XPanelMapPointTip:_GetStudyDataCostText(cost)
    return self._GameData:GetStudyDatas(self.PointObj:GetColorType()) >= cost and cost or XUiHelper.GetText("ColorTableNoEnoughCostTxt", cost)
end

-- 刷新效果
function XPanelMapPointTip:_RefreshBuff()
    local pointType = self.PointObj:GetType()
    local effectIds = self._GameManager:GetPointEffectList(pointType, self.PointObj:GetColorType())

    if self.PanelList then
        self.PanelList.gameObject:SetActiveEx(not XTool.IsTableEmpty(effectIds))
    end

    if XTool.IsTableEmpty(effectIds) then
        self.TxtNoBuff.gameObject:SetActiveEx(true)
    else
        self.TxtNoBuff.gameObject:SetActiveEx(false)
        self.PanelBuff.gameObject:SetActiveEx(false)
        for index, effectId in ipairs(effectIds) do
            if not self.GridEffects[index] then
                self.GridEffects[index] = XGridEffect.New(XUiHelper.Instantiate(self.PanelBuff, self.PanelBuffList))
            end
            self.GridEffects[index]:Refresh(effectId)
        end

        for i = #effectIds + 1, #self.GridEffects, 1 do
            self.GridEffects[i]:SetActive(false)
        end
    end
end

function XPanelMapPointTip:_AddBtnListener()
    if self.BtnGo then
        XUiHelper.RegisterClickEvent(self, self.BtnGo, self._OnBtnGoClick)
    end
    if self.BtnDo then
        XUiHelper.RegisterClickEvent(self, self.BtnDo, self._OnBtnDoClick)
    end
    if self.BtnDSpecial then
        XUiHelper.RegisterClickEvent(self, self.BtnDSpecial, self._OnBtnDSpecialClick)
    end
    if self.BtnCure then
        XUiHelper.RegisterClickEvent(self, self.BtnCure, self._OnBtnCureClick)
    end
end

function XPanelMapPointTip:_OnBtnGoClick()
    self:BeforeClick()
    self._GameManager:RequestMove(self.PointObj:GetPositionId())
end

function XPanelMapPointTip:_OnBtnDoClick()
    self:BeforeClick()
    if self.PointObj:IsMapPoint() then
        if XTool.IsNumberValid(self.NoramlExeCode) then
            XUiManager.TipCode(self.NoramlExeCode)
            return
        end
        self:CheckIsInPointBeforDoAction(function ()
            self.PointObj:Excute()
        end)
    end
end

function XPanelMapPointTip:_OnBtnDSpecialClick()
    self:BeforeClick()
    if self.PointObj:GetType() ~= XColorTableConfigs.PointType.Hospital then
        return
    end
    if XTool.IsNumberValid(self.SpecialExeCode) then
        XUiManager.TipCode(self.SpecialExeCode)
        return
    end
    self:CheckIsInPointBeforDoAction(function ()
        self._GameManager:RequestExecute(1)
    end)
end

-- 根除病毒
function XPanelMapPointTip:_OnBtnCureClick()
    self:BeforeClick()
    if self.PointObj:GetType() ~= XColorTableConfigs.PointType.Hospital then
        return
    end
    if XTool.IsNumberValid(self.SpecialExeCode) then
        XUiManager.TipCode(self.SpecialExeCode)
        return
    end
    self:CheckIsInPointBeforDoAction(function ()
        self._GameManager:RequestExecute(1)
    end)
end

-- 执行行动前如果不在该点则先移动到该点
function XPanelMapPointTip:CheckIsInPointBeforDoAction(yesCallBack)
    local positonId = self.PointObj:GetPositionId()
    if XTool.IsNumberValid(positonId) then
        local curPostionId = self._GameData:GetCurPosition()
        if positonId == curPostionId then
            if yesCallBack then
                yesCallBack()
            end
        else
            self._GameManager:RequestMove(positonId, yesCallBack)
        end
    end
end

function XPanelMapPointTip:BeforeClick()
    self:SetNothingDoCount(0)
    self.Root:BeforeBtnClick()
end

------------------------------------------------------------------

return XPanelMapPointTip