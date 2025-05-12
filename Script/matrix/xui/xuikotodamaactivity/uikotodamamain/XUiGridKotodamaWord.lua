---@class XUiGridKotodamaWord
---@field _Control XKotodamaActivityControl
local XUiGridKotodamaWord = XClass(XUiNode, 'UiGridKotodamaWord')

function XUiGridKotodamaWord:OnStart()
    self.BtnClick = self.GameObject:GetComponent(typeof(CS.XUiComponent.XUiButton))
    self.BtnClick.CallBack = handler(self, self.OnClickEvent)
end

function XUiGridKotodamaWord:Refresh(data)
    self.data = data
    self.BtnClick:SetName(data.Content)
    -- 增加解锁判定
    self.IsUnlock = self._Control:CheckWordIsUnLock(data.Id)
    
    self.BtnClick:SetButtonState(self.IsUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiGridKotodamaWord:OnClickEvent()
    if not self.IsUnlock then
        XUiManager.TipMsg(self._Control:GetClientConfigStringByKey('WordUnLockTips'))
        return
    end
    
    if self.Parent.CurBlockGrid then
        self._Control:SetAndCheckWordSpell(self.Parent.CurBlockGrid.patternIndex, self.Parent.CurBlockGrid.patternId,
                self.Parent.CurBlockGrid.wordIndex, self.data.Id, function()
                    self.Parent:RefreshWordPanel()
                    self.Parent:RefreshWordBlockSelection()
                    --如果拼对了就播动画
                    if self._Control:CheckCurStageSpellValid() then
                        self.Parent.Parent:PlayAnimation('Pulaomove')
                    end
                end)
    end
end

return XUiGridKotodamaWord