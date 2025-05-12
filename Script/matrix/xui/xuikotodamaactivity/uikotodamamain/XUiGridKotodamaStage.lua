---@class XUiGridKotodamaStage
---@field _Control XKotodamaActivityControl
local XUiGridKotodamaStage = XClass(XUiNode, 'UiGridKotodamaStage')

function XUiGridKotodamaStage:OnStart(id)
    self.Id = id
    self.BtnClick.CallBack = handler(self, self.OnClickEvent)
    local cfg = self._Control:GetKotodamaStageCfgById(self.Id)
    self.BtnClick:SetNameByGroup(0, cfg.StageTitleEx)
end

function XUiGridKotodamaStage:Refresh()
    local cfg = self._Control:GetKotodamaStageCfgById(self.Id)
    if cfg then
        --设置图片
        self.BtnClick:SetRawImage(cfg.StageIcon)
    end
    --是否解锁
    self.IsUnLock, self.StageIsInTime, self.PreIsPass, self.BranchUnLock = XMVCA.XKotodamaActivity:CheckStageIsUnLockById(self.Id)
    if not self.IsUnLock then
        self.BtnClick:SetButtonState(CS.UiButtonState.Disable)
    end
    self.Image.gameObject:SetActiveEx(self.IsUnLock)
    self.ImgSpeech.gameObject:SetActiveEx(self.IsUnLock)
    self.TxtNum.gameObject:SetActiveEx(self.IsUnLock)
    if not self.IsUnLock then
        return
    end

    --语录解锁情况
    if cfg then
        local totalCount = 0
        for i, v in pairs(cfg.SentencePatterns or {}) do
            local allSentence = self._Control:GetCollectableSentenceCountByPatternId(v)
            if XTool.IsTableEmpty(allSentence) == false then
                totalCount = totalCount + #allSentence
            end
        end
        self.TxtNum.text = self._Control:GetCollectUnLockSentenceCountById(self.Id) .. '/' .. totalCount
    else
        self.TxtNum.text = '0/0'
    end

    --新旧情况
    self.BtnClick:ShowReddot(XMVCA.XKotodamaActivity:CheckStageIsNew(self.Id))
end

function XUiGridKotodamaStage:OnClickEvent()
    if not self.IsUnLock then
        local msg = ''
        if not self.StageIsInTime then
            msg = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('StageNotInTime'), XMVCA.XKotodamaActivity:GetStageUnLockLeftTime(self.Id))
        elseif not self.PreIsPass then
            msg = self._Control:GetClientConfigStringByKey('PreStageNotPassed')
        elseif not self.BranchUnLock then
            msg = self._Control:GetClientConfigStringByKey('BranchStageUnlockTips')
        end
        XUiManager.TipMsg(msg)
        return
    end
    --更新选关
    if self._Control:GetCurStageId() ~= self.Id then
        local lastId = self._Control:GetCurStageId()
        --获取选择关的最新通关的选词情况
        local spelldata = self._Control:GetPassStageSpell(self.Id) or {}
        local deleteData = self._Control:GetPassStageDeleteSentences(self.Id) or 0
        --切换关卡先检查上一关的重置情况
        XMVCA.XKotodamaActivity:CheckAndSubmitReset(function()
            --将上一关的历史拼词数据覆盖到“当前关”字段
            self._Control:KotodamaCurStageDataRewriteLocal(function()
                XMVCA.XKotodamaActivity:SetStageNewState(self.Id, XEnumConst.KotodamaActivity.LocalNewState.Old)
                self.Parent:RefreshPulaoAvatarPosition(lastId, self._Control:GetCurStageId())
                self.Parent:FocusCurStageUI()
                self.Parent:RefreshWordBlockSelection(true)
                self.Parent.Parent:PlayAnimation('QieHuan')--动画在XUiKotodamaMain脚本所引用的GameObject下
                --检测一次入口
                self._Control:CheckCurStageSpellValid()
                self.Parent:RefreshBtnTongBlackState()
            end, self.Id, spelldata, deleteData)
        end)

    end

end

function XUiGridKotodamaStage:GetPulaoStandingPosition()
    local pos = self.PanelPulao.transform.localPosition + self.Transform.localPosition + self.Transform.parent.localPosition
    return pos
end

function XUiGridKotodamaStage:Select()
    self.Parent:RecordStageSelection(self, true)
    self.BtnClick:SetButtonState(CS.UiButtonState.Select)
    self.BtnClick.enabled = false
end

function XUiGridKotodamaStage:UnSelect()
    self.Parent:RecordStageSelection(self, false)
    self.BtnClick:SetButtonState(CS.UiButtonState.Normal)
    self.BtnClick.enabled = true
end

return XUiGridKotodamaStage