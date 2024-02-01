local XUiGridKotodamaWord=XClass(XUiNode,'UiGridKotodamaWord')

function XUiGridKotodamaWord:OnStart()
    self.BtnClick=self.GameObject:GetComponent(typeof(CS.XUiComponent.XUiButton))
    self.BtnClick.CallBack=handler(self,self.OnClickEvent)
end

function XUiGridKotodamaWord:Refresh(data)
    self.data=data
    self.BtnClick:SetName(data.Content)
end

function XUiGridKotodamaWord:OnClickEvent()
    if self.Parent.CurBlockGrid then
        self._Control:SetAndCheckWordSpell(self.Parent.CurBlockGrid.patternIndex,self.Parent.CurBlockGrid.patternId,
                self.Parent.CurBlockGrid.wordIndex,self.data.Id,function()
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