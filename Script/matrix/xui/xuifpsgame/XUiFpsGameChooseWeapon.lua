---@class XUiFpsGameChooseWeapon : XLuaUi 武器选择界面
---@field _Control XFpsGameControl
---@field PanelDetail UnityEngine.RectTransform
local XUiFpsGameChooseWeapon = XLuaUiManager.Register(XLuaUi, "UiFpsGameChooseWeapon")

local Normal = 1            -- 普通
local HandbookMode = 2      -- 图鉴
local ShowWeaponMode = 3    -- 武器展示
local DelayTime = CS.XGame.ClientConfig:GetInt("ArchiveWeaponShowDelayTime")

function XUiFpsGameChooseWeapon:OnAwake()
    ---@type UnityEngine.Vector3
    self._TempVec3 = Vector3(0, 0, 0)
    ---@type UnityEngine.RectTransform
    self._RectTransform = self.Transform:GetComponent("RectTransform")
    self.BtnClose.CallBack = handler(self, self.OnBtnTipCloseClick)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
    self.BtnSet.CallBack = handler(self, self.OnBtnSetClick)
end

---@param stageId number 图鉴模型下可以传0
---@param selectWeaponId number 图鉴模式下可以传0，展示武器模式下传武器Id
function XUiFpsGameChooseWeapon:OnStart(stageId, selectWeaponId)
    self._StageId = stageId
    self._SelectWeaponId = selectWeaponId
    self._StageConfig = XTool.IsNumberValid(stageId) and self._Control:GetStageById(stageId) or nil

    if not stageId then
        self._Mode = HandbookMode
    elseif selectWeaponId then
        self._Mode = ShowWeaponMode
    else
        self._Mode = Normal
    end

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self:InitScene3DRoot()
    self:BindHelpBtn(self.BtnHelp, "FpsGameWeaponHelp")
    XUiHelper.NewPanelTopControl(self, self.TopControlVariable)
end

function XUiFpsGameChooseWeapon:OnEnable()
    self.Super.OnEnable(self)
    self:OnBtnTipCloseClick()
    self._BattleWeapon = {}

    self:InitWeaponGroup()
    if self._Mode == Normal then
        self.ListCharacter.gameObject:SetActiveEx(true)
        self.BtnEnter.gameObject:SetActiveEx(true)
        self:InitCharacterGroup()
    else
        self.ListCharacter.gameObject:SetActiveEx(false)
        self.BtnEnter.gameObject:SetActiveEx(false)
    end
end

function XUiFpsGameChooseWeapon:OnDisable()
    XSaveTool.SaveData(self._Control:GetWeaponKey(), self._BattleWeapon)
    if self._CurSelectCharIdx then
        XSaveTool.SaveData(self._Control:GetCharacterKey(), self._CurSelectCharIdx)
    end
end

function XUiFpsGameChooseWeapon:OnDestroy()
    self.Scene3DRoot.PanelWeaponPlane.gameObject:SetActiveEx(true)
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

--region 武器（多选）

function XUiFpsGameChooseWeapon:InitWeaponGroup()
    ---@type XUiGridFpsGameWeapon[]
    self._WeaponGrids = {}
    local btns = {}
    local selectIndex = 1
    local weaponIds = {}
    self._WeaponDatas = self._Control:GetWeapons()
    XUiHelper.RefreshCustomizedList(self.GridWeapon.parent, self.GridWeapon, #self._WeaponDatas, function(index, go)
        local weapon = self._WeaponDatas[index]
        ---@type XUiGridFpsGameWeapon
        local grid = require("XUi/XUiFpsGame/XUiGridFpsGameWeapon").New(go, self, weapon)
        grid:RefreshCondition()
        self._WeaponGrids[index] = grid
        table.insert(btns, grid.GridWeapon)
        if weapon.Id == self._SelectWeaponId then
            selectIndex = index
        end
        weaponIds[weapon.Id] = index
    end)
    self.WeaponGroup:Init(btns, function(index)
        self:OnSelectWeapon(index)
    end)
    if self._Mode == Normal then
        local weaponIdxs = self._StageConfig.SelectWeapons
        if XTool.IsTableEmpty(weaponIdxs) then
            weaponIdxs = XSaveTool.GetData(self._Control:GetWeaponKey())
        end
        if not XTool.IsTableEmpty(weaponIdxs) then
            for pos, weaponId in pairs(weaponIdxs) do
                if weaponId then
                    self:UpdateBattleWeapon(weaponIds[weaponId], weaponId, pos)
                end
            end
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.WeaponGroup.transform)
    self:SetWeaponSelectState(selectIndex)
end

function XUiFpsGameChooseWeapon:OnSelectWeapon(index)
    self:SetWeaponSelectState(index)
    -- 图鉴和展示模式下不能选择出战武器；有指定的武器时也不能选择其他武器
    if self._Mode == Normal and XTool.IsTableEmpty(self._StageConfig.SelectWeapons) then
        self:UpdateBattleWeapon(index, self._WeaponDatas[index].Id)
    end
end

function XUiFpsGameChooseWeapon:SetWeaponSelectState(index)
    self:ShowWeaponTip(self._WeaponDatas[index], self._WeaponGrids[index])
    self:UpdateWeaponModel(self._WeaponDatas[index].TemplateId)
end

---@param index number 格子索引
---@param weaponId number 武器Id
---@param position number 出战位
function XUiFpsGameChooseWeapon:UpdateBattleWeapon(index, weaponId, position)
    local grid = self._WeaponGrids[index]
    if grid:IsLock() then
        return
    end
    local gridPos = grid:GetPosition()
    if XTool.IsNumberValid(gridPos) then
        grid:SetPosition(0)
        self._BattleWeapon[gridPos] = nil
    else
        local pos = position or self:GetCurPosition()
        if not pos then
            XUiManager.TipError(XUiHelper.GetText("FpsGameWeaponFull"))
            return
        end
        grid:SetPosition(pos)
        self._BattleWeapon[pos] = weaponId
    end
end

function XUiFpsGameChooseWeapon:GetCurPosition()
    for i = 1, 3 do
        if not self._BattleWeapon[i] then
            return i
        end
    end
    return nil
end

---@param weapon XTableFpsGameWeapon
---@param grid XUiGridFpsGameWeapon
function XUiFpsGameChooseWeapon:ShowWeaponTip(weapon, grid)
    if not weapon then
        self.PanelDetail.gameObject:SetActiveEx(false)
        return
    end

    self.PanelDetail.gameObject:SetActiveEx(true)
    self.TxtTipName.text = weapon.Name
    self.TxtTipType.text = weapon.Title
    if XTool.IsNumberValid(weapon.UnlockCondition) then
        local isUnlock, desc = XConditionManager.CheckCondition(weapon.UnlockCondition)
        if isUnlock then
            self.TxtLockTips.gameObject:SetActiveEx(false)
        else
            self.TxtLockTips.gameObject:SetActiveEx(true)
            self.TxtLockTips.text = desc
        end
    else
        self.TxtLockTips.gameObject:SetActiveEx(false)
    end

    local uiObject
    local skillCount = #weapon.SkillIcon
    XUiHelper.RefreshCustomizedList(self.GridSkill.parent, self.GridSkill, skillCount, function(index, go)
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgSkill:SetRawImage(weapon.SkillIcon[index])
        uiObject.TxtType.text = weapon.SkillName[index]
        uiObject.TxtDetail.text = XUiHelper.ReplaceTextNewLine(weapon.SkillDesc[index])
        uiObject.ImgLine.gameObject:SetActiveEx(index < skillCount)
    end)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDetail)

    --local worldPos = grid.Transform.parent.localToWorldMatrix:MultiplyPoint(grid.Transform.localPosition)
    --local localPos = self.PanelDetail.parent.worldToLocalMatrix:MultiplyPoint(worldPos)
    --if self.PanelDetail.rect.height - localPos.y > self._RectTransform.rect.height / 2 then
    --    localPos.y = self.PanelDetail.rect.height - self._RectTransform.rect.height / 2
    --end
    --self._TempVec3:Set(self.PanelDetail.localPosition.x, localPos.y, self.PanelDetail.localPosition.z)
    --self.PanelDetail.localPosition = self._TempVec3
end

function XUiFpsGameChooseWeapon:OnBtnTipCloseClick()
    self:ShowWeaponTip()
end

--endregion

--region 支援角色（单选）

function XUiFpsGameChooseWeapon:InitCharacterGroup()
    if not self._StageConfig then
        XLog.Error("关卡Id为空.")
        return
    end
    local btns = {}
    self._CharacterGrids = {}
    local characters = self._Control:GetChapterById(self._StageConfig.ChapterId).Robot
    XUiHelper.RefreshCustomizedList(self.GridCharacter.parent, self.GridCharacter, #characters, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        local charIcon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characters[index])
        uiObject.RImgCharacter:SetRawImage(charIcon)
        self._CharacterGrids[index] = uiObject
        table.insert(btns, uiObject.GridCharacter)
    end)
    local idx
    local customRobotId = self._StageConfig.OnlyUseRobotId
    if XTool.IsNumberValid(customRobotId) then
        idx = table.indexof(characters, customRobotId)
        if not idx then
            idx = 1
            XLog.Error("Stage表里不存在Id=" .. self._StageConfig.OnlyUseRobotId .. "的角色")
        end
        -- 不允许选择角色
        for i, grid in ipairs(self._CharacterGrids) do
            grid.GridCharacter.gameObject:SetActiveEx(i == idx)
        end
        self.TxtSupport.gameObject:SetActiveEx(false)
    elseif #characters == 0 then
        self.TxtSupport.gameObject:SetActiveEx(false)
    else
        idx = XSaveTool.GetData(self._Control:GetCharacterKey())
        -- 可自由选择支援角色
        self.TxtSupport.gameObject:SetActiveEx(true)
    end
    if self._StageConfig.ChapterId == XEnumConst.FpsGame.Story and not XTool.IsNumberValid(customRobotId) then
        -- 剧情模式如果没配置OnlyUseRobotId，则隐藏所有角色且不可选择
        self.TxtSupport.gameObject:SetActiveEx(false)
        self.GridCharacter.parent.gameObject:SetActiveEx(false)
    else
        self.GridCharacter.parent.gameObject:SetActiveEx(true)
        self.CharacterGroup:Init(btns, function(index)
            self:OnSelectCharacter(index, characters[index])
        end)
        if idx then
            self.CharacterGroup:SelectIndex(idx)
        end
    end
end

function XUiFpsGameChooseWeapon:OnSelectCharacter(index, charId)
    self._CurSelectCharId = charId
    self._CurSelectCharIdx = index
end

--endregion

--region 3D武器展示

function XUiFpsGameChooseWeapon:InitScene3DRoot()
    if self.Scene3DRoot then
        return
    end
    self.Scene3DRoot = {}
    self.Scene3DRoot.Transform = self.UiSceneInfo.Transform
    self.Scene3DRoot.AutoRationPanel = self.UiModelGo:FindTransform("PanelWeapon"):GetComponent(typeof(CS.XAutoRotation))
    self.Scene3DRoot.PanelEffect = self.UiModelGo:FindTransform("EffectGo")
    self.Scene3DRoot.PanelWeaponPlane = self.UiSceneInfo.Transform:FindTransform("Plane")
    self.Scene3DRoot.PanelWeaponPlane.gameObject:SetActiveEx(false)
end

function XUiFpsGameChooseWeapon:UpdateWeaponModel(templateId)
    local modelCfgList = XMVCA.XEquip:GetWeaponModelCfgList(templateId, self.Name, 0)
    local modelConfig = modelCfgList[1]
    self._Timer = XScheduleManager.ScheduleOnce(function()
        XModelManager.LoadWeaponModel(modelConfig.ModelId, self.Scene3DRoot.AutoRationPanel.transform, modelConfig.TransformConfig, self.Name, function(model)
            model.gameObject:SetActiveEx(true)
            local panelEffect = self.Scene3DRoot.PanelEffect
            panelEffect.gameObject:SetActiveEx(false)
            panelEffect.gameObject:SetActiveEx(true)
        end, { gameObject = self.GameObject, AntiClockwise = true })
    end, DelayTime)
end

--endregion

function XUiFpsGameChooseWeapon:OnBtnEnterClick()
    if not self._BattleWeapon[1] then
        -- 未选首发武器
        XUiManager.TipError(XUiHelper.GetText("FpsGameBattleNoWeapon"))
        return
    end
    -- 佣兵模式下，仅选满武器后，才允许进入战斗
    if self._StageConfig and self._StageConfig.ChapterId == XEnumConst.FpsGame.Challenge then
        if not self._BattleWeapon[2] or not self._BattleWeapon[3] then
            XUiManager.TipError(XUiHelper.GetText("FpsGameBattleFullWeapon"))
            return
        end
    end
    self._Control:EnterFight(self._StageId, self._BattleWeapon, self._CurSelectCharId)
    XLuaUiManager.Remove("UiFpsGameChooseWeapon")
    -- self:Close() 这里Close会引起战斗内剧情的bug 界面不会被销毁
end

function XUiFpsGameChooseWeapon:OnBtnSetClick()
    XLuaUiManager.Open("UiSet")
end

return XUiFpsGameChooseWeapon