local XUiGridAreaWarBlock = XClass(nil, "XUiGridAreaWarBlock")

function XUiGridAreaWarBlock:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClick)
    end
    if self.EffectAttack then
        self.EffectAttack.gameObject:SetActiveEx(false)
    end
    self:SetFighting(false)

    self.PanelJdEnable = self.Transform:FindTransform("PanelJdEnable")
    self.PanelJdDisable = self.Transform:FindTransform("PanelJdDisable")
end

function XUiGridAreaWarBlock:Refresh(blockId)
    --初始区块不做更新
    if XAreaWarConfigs.IsInitBlock(blockId) then
        return
    end

    self.BlockId = blockId
    local block = XDataCenter.AreaWarManager.GetBlock(blockId)

    if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.NormalCharacter) then
        if self.RImgRole then
            self.RImgRole:SetRawImage(XAreaWarConfigs.GetRoleBlockIcon(blockId))
        end
    end

    if self.TxtName then
        self.TxtName.text = XAreaWarConfigs.GetBlockNameEn(blockId)
    end

    if self.TxtTime then
        local tips = ""
        if XDataCenter.AreaWarManager.GetBlockUnlockLeftTime(blockId) > 0 then
            --优先判断时间是否达到
            local openTime = XDataCenter.AreaWarManager.GetBlockUnlockTime(blockId)
            local timeFormat = CsXTextManagerGetText("AreaWarBlockLockTimeFormat")
            tips =
                CsXTextManagerGetText("AreaWarBlockLockTime", XTime.TimestampToGameDateTimeString(openTime, timeFormat))
        else
            tips = CsXTextManagerGetText("AreaWarBlockLock")
        end
        tips = XUiHelper.ConvertLineBreakSymbol(tips)
        self.TxtTime.text = tips
    end

    local isClear = XDataCenter.AreaWarManager.IsBlockClear(blockId) --已净化
    local isFighting = XDataCenter.AreaWarManager.IsBlockFighting(blockId) --战斗中
    local isLock = XDataCenter.AreaWarManager.IsBlockLock(blockId) --未解锁
    if self.EffectClear then
        self.EffectClear.gameObject:SetActiveEx(isClear)
    end
    if self.EffectDisable then
        self.EffectDisable.gameObject:SetActiveEx(isLock)
    end
    if self.EffectNormal then
        self.EffectNormal.gameObject:SetActiveEx(isFighting)
    end
    if self.PanelClear then
        self.PanelClear.gameObject:SetActiveEx(isClear)
    end
    if self.PanelDisable then
        self.PanelDisable.gameObject:SetActiveEx(isLock)
    end
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(isFighting)
    end

    --进度条
    local progress = block:GetProgress()
    if self.RImgJd then
        self.RImgJd.fillAmount = progress
    end
    if self.TxtProgress then
        self.TxtProgress.text = math.floor(progress * 100) .. "%"
    end

    --作战中特效
    self:SetFighting(isFighting)
end

--战斗中状态
function XUiGridAreaWarBlock:SetFighting(value)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(value)
    end
end

function XUiGridAreaWarBlock:OnClick()
    if self.ClickCb then
        self.ClickCb(self.BlockId)
    end
end

function XUiGridAreaWarBlock:PlayNearAnim()
    if self.PanelJdEnable then
        if self.PanelJdEnable.gameObject.activeInHierarchy then
            XLuaUiManager.SetMask(true)
            self.PanelJdEnable:PlayTimelineAnimation(
                function()
                    XLuaUiManager.SetMask(false)
                end
            )
        end
    end
end

function XUiGridAreaWarBlock:PlayFarAnim()
    if self.PanelJdDisable then
        if self.PanelJdDisable.gameObject.activeInHierarchy then
            XLuaUiManager.SetMask(true)
            self.PanelJdDisable:PlayTimelineAnimation(
                function()
                    XLuaUiManager.SetMask(false)
                end
            )
        end
    end
end

return XUiGridAreaWarBlock
