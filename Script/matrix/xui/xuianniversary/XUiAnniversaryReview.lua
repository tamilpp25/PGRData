--周年回顾界面
local XUiAnniversaryReview=XLuaUiManager.Register(XLuaUi,'UiAnniversaryReview')
local XUiGridAnniversaryReview=require('XUi/XUiAnniversary/XUiGridAnniversaryReview')
--region 生命周期
function XUiAnniversaryReview:OnAwake()
    self.DynamicTable=XDynamicTableNormal.New(self.List)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridAnniversaryReview,self)
    self.DynamicTable.Imp:onEndDragEvent('+',handler(self,self.OnEndDragEvent))
    self.PanelReport.gameObject:SetActiveEx(false)
    self.Panelshare.gameObject:SetActiveEx(false)
    self.ReportPanelCtrl=require('XUi/XUiAnniversary/XUiPanelAnniversaryReviewReport').New(self.PanelReport,self)
    self.SharePanelCtrl=require('XUi/XUiAnniversary/XUiPanelAnniversaryReviewShare').New(self.Panelshare,self)
    self.GridUi.gameObject:SetActiveEx(false)
    
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
end

function XUiAnniversaryReview:OnStart()
    self.DynamicTable:SetTotalCount(self._Control:GetReviewPicturesCount())
    self.DynamicTable:ReloadDataSync()
    --初始化时手动修正一次位置
    self:OnEndDragEvent()
end
--endregion

--region 事件处理
function XUiAnniversaryReview:OnDynamicTableEvent(event, index, grid)
    if event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end

function XUiAnniversaryReview:OnEndDragEvent()
    --位置修正
    if not self.isFixing then
        self.isFixing=true
        self.ScrollView:StopMovement()
        --找到距离当前锚点位置最近的修正点
        local _anchoredPos=self.ScrollView.content.anchoredPosition
        local posdiff=9999999
        for i, v in pairs(self._Control:GetReviewPictures()) do
            if XTool.IsNumberValid(v.FocusAnchoredY) then
                local tempDiff=(v.FocusAnchoredY*Vector2.up-self.ScrollView.content.anchoredPosition).magnitude
                if tempDiff<posdiff then
                    posdiff=tempDiff
                    _anchoredPos=v.FocusAnchoredY
                end
            end
        end
        --插值
        self.ScrollView.content:DOAnchorPosY(_anchoredPos,CS.XGame.ClientConfig:GetFloat('AnniversaryReviewFixPosSpeed')):SetSpeedBased(true):OnComplete(function() 
            self.isFixing=false
            self.ScrollView:StopMovement()
        end)
    end
end

function XUiAnniversaryReview:OpenReportPanel()
    self.ReportPanelCtrl:Open()
end

function XUiAnniversaryReview:OpenShare()
    if not self.IsCreatePng then
        local ctrl=XMVCA.XAnniversary:CreateAlbumControl()
        ctrl:CreateShortAlbum(function(_shortT2d)
            ctrl:CreateLongAlbum(function(_longT2d)
                self.IsCreatePng=true
                self.SharePanelCtrl:Init(_longT2d,_shortT2d,ctrl)
                self.SharePanelCtrl:Open()
            end)
        end)
    else
        self.SharePanelCtrl:Open()
    end
    
end
--endregion

return XUiAnniversaryReview