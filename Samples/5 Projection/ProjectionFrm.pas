unit ProjectionFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects,

  System.IOUtils,

  CoreClasses, PascalStrings, UnicodeMixedLib,
  Geometry2DUnit,
  zDrawEngine, MemoryRaster, zDrawEngineInterface_SlowFMX, FMX.Layouts;

type
  TProjectionForm = class(TForm)
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    s_LeftTop: TCircle;
    s_RightTop: TCircle;
    s_LeftBottom: TCircle;
    s_RightBottom: TCircle;
    d_RightTop: TCircle;
    d_LeftTop: TCircle;
    d_LeftBottom: TCircle;
    d_RightBottom: TCircle;
    s_Image: TImage;
    d_Image: TImage;
    procedure FormCreate(Sender: TObject);
    procedure cMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure cMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure cMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure cPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    { Private declarations }
  public
    { Public declarations }
    ori, sour, dest: TMemoryRaster;

    downObj: TCircle;
    lastPt: TPointf;

    procedure RunProj;
  end;

var
  ProjectionForm: TProjectionForm;

implementation

{$R *.fmx}


procedure TProjectionForm.FormCreate(Sender: TObject);
begin
  ori := NewRasterFromFile(umlCombineFileName(TPath.GetLibraryPath, 'lena.bmp'));

  sour := NewRaster();
  sour.Assign(ori);

  s_Image.SetBounds(0, 0, sour.Width, sour.Height);
  MemoryBitmapToBitmap(sour, s_Image.Bitmap);

  dest := NewRaster();
  dest.SetSize(round(d_Image.Width), round(d_Image.Height), RasterColor(0, 0, 0));
  MemoryBitmapToBitmap(dest, d_Image.Bitmap);

  downObj := nil;
  lastPt := Pointf(0, 0);
  RunProj();
end;

procedure TProjectionForm.cMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  downObj := TCircle(Sender);
  lastPt := TControl(downObj.Parent).AbsoluteToLocal(downObj.LocalToAbsolute(Pointf(X, Y)));
end;

procedure TProjectionForm.cMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  pt: TPointf;
begin
  if downObj <> Sender then
      exit;

  pt := TControl(downObj.Parent).AbsoluteToLocal(downObj.LocalToAbsolute(Pointf(X, Y)));

  downObj.Position.Point := downObj.Position.Point + (pt - lastPt);
  lastPt := pt;
end;

procedure TProjectionForm.cMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  downObj := nil;
  RunProj();
end;

procedure TProjectionForm.cPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  n: U_String;
begin
  Canvas.Fill.Color := TAlphaColorRec.Red;
  n := TComponent(Sender).Name;
  n.DeleteFirst;
  n.DeleteFirst;
  Canvas.FillText(ARect, n, False, 1.0, [], TTextAlign.Leading);
end;

procedure TProjectionForm.RunProj;
var
  ps, pd: TV2Rect4;
begin
  ps.LeftTop := Vec2(s_LeftTop.BoundsRect.CenterPoint);
  ps.RightTop := Vec2(s_RightTop.BoundsRect.CenterPoint);
  ps.RightBottom := Vec2(s_RightBottom.BoundsRect.CenterPoint);
  ps.LeftBottom := Vec2(s_LeftBottom.BoundsRect.CenterPoint);

  pd.LeftTop := Vec2(d_LeftTop.BoundsRect.CenterPoint);
  pd.RightTop := Vec2(d_RightTop.BoundsRect.CenterPoint);
  pd.RightBottom := Vec2(d_RightBottom.BoundsRect.CenterPoint);
  pd.LeftBottom := Vec2(d_LeftBottom.BoundsRect.CenterPoint);

  sour.Assign(ori);

  dest.SetSize(round(d_Image.Width), round(d_Image.Height), RasterColor(0, 0, 0));

  // ProjectionTo�ǻ��ڿ���ͶӰ��ԭ�ӷ���(���ײ��������vertex)
  // ԭ����4�����ԭ��ͶӰ��Ŀ��4�����Ŀ��
  // MemoryRasterͶӰʹ����4���������������������(TV2Rect4)��TRect���������������ȱ߿���
  // TV2Rect4ӵ�м������ţ�������ת������ƽ�ƣ���Χ������ȵȻ������ܣ���MemoryRasterӵ�����ػ�Ϲ��ܣ����߽�Ͼ���2dͶӰ�������
  // MemoryRasterͶӰʹ��˫����ƴ�ӳɲ�������壬���ڲ����������΢��ͶӰ����ͬ�����ǳ��õ��ǶԳƾ���ͶӰ������ͶӰ�Ǹ��Ӽ���ͶӰ�ĵػ�֧��
  // ��zAI��ͼ�����У�ͶӰ������Ӧ���ڶ��룬���գ��߶ȿռ䣬������MemoryRaster���ֶ���ͶӰ
  // ͶӰ�����ض��ǰ�alpha��ϵ��ӵģ����Ǹ���
  // �����ֿ�ͶӰ��Draw�ĸ��ͶӰ�����������draw�ǵ�һ�����
  dest.OpenAgg;
  dest.Agg.LineWidth:=2;
  dest.Vertex.DrawTriangleEdge:=True;
  sour.ProjectionTo(dest, ps, pd, True, 1.0);

  MemoryBitmapToBitmap(dest, d_Image.Bitmap);

  sour.Agg.LineWidth := 5;
  sour.DrawRect(ps, RasterColorF(1, 0.5, 0.5));
  MemoryBitmapToBitmap(sour, s_Image.Bitmap);
end;

end.
