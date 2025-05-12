---@class XUiFpsGameSettlement : XLuaUi 挑战模型胜利结算（关卡内）
---@field _Control XFpsGameControl
local XUiFpsGameSettlement = XLuaUiManager.Register(XLuaUi, "UiFpsGameSettlement")

function XUiFpsGameSettlement:OnAwake()
    self.BtnExit.CallBack = handler(self, self.Close)
    self.BtnAgain.CallBack = handler(self, self.OnBtnAgainClick)
end

function XUiFpsGameSettlement:OnStart(settleData)
    self._SettleData = settleData
    self._FightData = XMVCA.XFuben:GetCurFightResult()
    self._Star = self._Control:GetStarsCount(self._FightData.AddStars)
    self._StageId = self._FightData.StageId
    self._StageConfig = self._Control:GetStageById(self._StageId)
end

function XUiFpsGameSettlement:OnEnable()
    self.Super.OnEnable(self)
    self:SetMouseVisible()
    -- 评分
    local score = self._SettleData.FpsGameSettleResult.Score
    self.TxtScoreNum.text = score
    self.PanelNew.gameObject:SetActiveEx(self._SettleData.FpsGameSettleResult.IsNewRecord)
    local scoreLevel = self._Control:GetScoreLevel(score)
    if scoreLevel then
        self.RImgScore:SetRawImage(scoreLevel.LevelIcon)
        self.FxPutongLoop:LoadUiEffect(self._Control:GetClientConfigById("ScoreEffectUrl", scoreLevel.Id))
    end
    -- 挑战目标
    self:ShowChallengeDim()
    -- 得分详情
    self:ShowScoreDetail()
end

function XUiFpsGameSettlement:OnDestroy()

end

function XUiFpsGameSettlement:ShowChallengeDim()
    local starDescs = self._StageConfig.StarDesc
    XUiHelper.RefreshCustomizedList(self.GridStageStar.parent, self.GridStageStar, #starDescs, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.PanelActive.gameObject:SetActiveEx(self._Star >= index)
        uiObject.PanelUnActive.gameObject:SetActiveEx(self._Star < index)
        uiObject.TxtUnActive.text = starDescs[index]
        uiObject.TxtActive.text = starDescs[index]

        if XTool.IsNumberValid(self._StageConfig.UnlockWeapon) and index == 1 then
            uiObject.GridWeapon.gameObject:SetActiveEx(true)
            local weaponConfig = self._Control:GetWeaponById(self._StageConfig.UnlockWeapon)
            ---@type XUiGridFpsGameWeapon
            local weaponGrid = require("XUi/XUiFpsGame/XUiGridFpsGameWeapon").New(uiObject.GridWeapon, self, weaponConfig)
            weaponGrid:SetReceive(self._Control:IsWeaponUnlock(self._StageConfig.UnlockWeapon))
        else
            uiObject.GridWeapon.gameObject:SetActiveEx(false)
        end
    end, true)
end

function XUiFpsGameSettlement:ShowScoreDetail()
    local scoreInfos = self:GetScoreInfos()
    if XTool.IsTableEmpty(scoreInfos) then
        self.ListDetail.gameObject:SetActiveEx(false)
    else
        self.ListDetail.gameObject:SetActiveEx(true)
        XUiHelper.RefreshCustomizedList(self.GridDetail.parent, self.GridDetail, #scoreInfos, function(index, go)
            local scoreInfo = scoreInfos[index]
            local scoreCfg = self._Control:GetScoreById(scoreInfo.Id)
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            uiObject.TxtTitle.text = string.gsub(scoreCfg.Desc, "{0}", XUiHelper.GetLargeIntNumText(scoreInfo.Value))
            if scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add then
                uiObject.TxtScoreNum.text = string.format("+%s", math.ceil(scoreCfg.Score * scoreInfo.Value / scoreCfg.Divisor))
            elseif scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY then
                -- 小数点后最多保留2位小数
                uiObject.TxtScoreNum.text = string.format("+%s%%", math.floor(scoreCfg.Score * scoreInfo.Value / (scoreCfg.Divisor / 100)))
            end
        end)
    end
end

-- 获取得分列表
function XUiFpsGameSettlement:GetScoreInfos()
    if not self._FightData or not self._FightData.IsWin or not self._FightData.IntToIntRecord then
        return nil
    end

    local scoreInfos = {}
    local e = self._FightData.IntToIntRecord:GetEnumerator()
    while e:MoveNext() do
        local scoreCfg = self._Control:GetScoreById(e.Current.Key)
        if scoreCfg then
            local isShow = e.Current.Value ~= 0 and (scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add or scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY)
            if isShow then
                local scoreInfo = { Id = e.Current.Key, Value = e.Current.Value }
                table.insert(scoreInfos, scoreInfo)
            end
        end
    end
    e:Dispose()

    -- 按照Order排序
    table.sort(scoreInfos, function(a, b)
        local aCfg = self._Control:GetScoreById(a.Id)
        local bCfg = self._Control:GetScoreById(b.Id)
        return aCfg.Order < bCfg.Order
    end)

    return scoreInfos
end

function XUiFpsGameSettlement:OnBtnAgainClick()
    self._Control:EnterFightAgain()
    self:Close()
end

function XUiFpsGameSettlement:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

return XUiFpsGameSettlement