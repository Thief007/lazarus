//
// AggPas 2.4 RM3 Demo application
// Note: Press F1 key on run to see more info about this demo
//
// Paths: src;src\ctrl;src\svg;src\util;src\platform\win;expat-wrap
//
program
 conv_stroke_ ;

uses
 agg_basics ,
 agg_platform_support ,

 agg_color ,
 agg_pixfmt ,
 agg_pixfmt_rgb ,

 agg_ctrl ,
 agg_slider_ctrl ,
 agg_rbox_ctrl ,
 agg_cbox_ctrl ,

 agg_renderer_base ,
 agg_renderer_scanline ,
 agg_rasterizer_scanline_aa ,
 agg_scanline ,
 agg_scanline_u ,
 agg_render_scanlines ,

 agg_conv_stroke ,
 agg_conv_dash ,
 agg_conv_curve ,
 agg_conv_contour ,
 agg_conv_smooth_poly1 ,
 agg_conv_marker ,
 agg_arrowhead ,
 agg_vcgen_markers_term ,
 agg_math ,
 agg_math_stroke ,
 agg_path_storage ;

{$I agg_mode.inc }

const
 flip_y = true;

type
 the_application = object(platform_support )
   m_x   ,
   m_y   : array[0..2 ] of double;
   m_dx  ,
   m_dy  : double;
   m_idx : int;

   m_join ,
   m_cap  : rbox_ctrl;

   m_width       ,
   m_miter_limit : slider_ctrl;

   constructor Construct(format_ : pix_format_e; flip_y_ : boolean );
   destructor  Destruct;

   procedure on_draw; virtual;

   procedure on_mouse_move       (x ,y : int; flags : unsigned ); virtual;
   procedure on_mouse_button_down(x ,y : int; flags : unsigned ); virtual;
   procedure on_mouse_button_up  (x ,y : int; flags : unsigned ); virtual;

   procedure on_key(x ,y : int; key ,flags : unsigned ); virtual;

  end;

{ CONSTRUCT }
constructor the_application.Construct;
begin
 inherited Construct(format_ ,flip_y_ );

 m_join.Construct       (10.0 ,10.0 ,133.0 ,80.0 ,not flip_y_ );
 m_cap.Construct        (10.0 ,80.0 + 10.0 ,133.0 ,80.0 + 80.0 ,not flip_y_ );
 m_width.Construct      (130 + 10.0 ,10.0 + 4.0 ,500.0 - 10.0 ,10.0 + 8.0 + 4.0 ,not flip_y_ );
 m_miter_limit.Construct(130 + 10.0 ,20.0 + 10.0 + 4.0 ,500.0 - 10.0 ,20.0 + 10.0 + 8.0 + 4.0 ,not flip_y_ );

 m_idx:=-1;

 m_x[0 ]:=57  + 100;
 m_y[0 ]:=60;
 m_x[1 ]:=369 + 100;
 m_y[1 ]:=170;
 m_x[2 ]:=143 + 100;
 m_y[2 ]:=310;

 add_ctrl(@m_join );

 m_join.text_size_     (7.5 );
 m_join.text_thickness_(1.0 );

 m_join.add_item ('Miter Join' );
 m_join.add_item ('Miter Join Revert' );
 m_join.add_item ('Round Join' );
 m_join.add_item ('Bevel Join' );
 m_join.cur_item_(2 );

 add_ctrl(@m_cap );

 m_cap.add_item ('Butt Cap' );
 m_cap.add_item ('Square Cap' );
 m_cap.add_item ('Round Cap' );
 m_cap.cur_item_(2 );

 add_ctrl(@m_width );

 m_width.range_(3.0 ,40.0 );
 m_width.value_(20.0 );
 m_width.label_('Width=%1.2f' );

 add_ctrl(@m_miter_limit );

 m_miter_limit.range_(1.0 ,10.0 );
 m_miter_limit.value_(4.0 );
 m_miter_limit.label_('Miter Limit=%1.2f' );

 m_join.no_transform;
 m_cap.no_transform;
 m_width.no_transform;
 m_miter_limit.no_transform;

end;

{ DESTRUCT }
destructor the_application.Destruct;
begin
 inherited Destruct;

 m_join.Destruct;
 m_cap.Destruct;
 m_width.Destruct;
 m_miter_limit.Destruct;

end;

{ ON_DRAW }
procedure the_application.on_draw;
var
 pixf : pixel_formats;
 rgba : aggclr;
 renb : renderer_base;
 ren  : renderer_scanline_aa_solid;
 ras  : rasterizer_scanline_aa;
 sl   : scanline_u8;

 cap  ,
 join : unsigned;
 path : path_storage;

 stroke ,
 poly1  ,
 poly2  : conv_stroke;

 poly2_dash : conv_dash;

begin
// Initialize structures
 pixfmt_bgr24(pixf ,rbuf_window );

 renb.Construct(@pixf );
 ren.Construct (@renb );

 rgba.ConstrDbl(1 ,1 ,1 );
 renb.clear    (@rgba );

 ras.Construct;
 sl.Construct;

// Render
 path.Construct;

 path.move_to(m_x[0 ] ,m_y[0 ] );
 path.line_to((m_x[0 ] + m_x[1 ] ) / 2 ,(m_y[0 ] + m_y[1 ] ) / 2 ); // This point is added only to check for numerical stability
 path.line_to(m_x[1 ] ,m_y[1 ] );
 path.line_to(m_x[2 ] ,m_y[2 ] );
 path.line_to(m_x[2 ] ,m_y[2 ] );                                   // This point is added only to check for numerical stability

 path.move_to((m_x[0 ] + m_x[1 ] ) / 2 ,(m_y[0 ] + m_y[1 ] ) / 2 );
 path.line_to((m_x[1 ] + m_x[2 ] ) / 2 ,(m_y[1 ] + m_y[2 ] ) / 2 );
 path.line_to((m_x[2 ] + m_x[0 ] ) / 2 ,(m_y[2 ] + m_y[0 ] ) / 2 );
 path.close_polygon;

 cap:=butt_cap;

 if m_cap._cur_item = 1 then
  cap:=square_cap;

 if m_cap._cur_item = 2 then
  cap:=round_cap;

 join:=miter_join;

 if m_join._cur_item = 1 then
  join:=miter_join_revert;

 if m_join._cur_item = 2 then
  join:=round_join;

 if m_join._cur_item = 3 then
  join:=bevel_join;

// (1)
 stroke.Construct   (@path );
 stroke.line_join_  (join );
 stroke.line_cap_   (cap );
 stroke.miter_limit_(m_miter_limit._value );
 stroke.width_      (m_width._value );

 ras.add_path    (@stroke );
 rgba.ConstrDbl  (0.8 ,0.7 ,0.6 );
 ren.color_      (@rgba );
 render_scanlines(@ras ,@sl ,@ren );

// (2)
 poly1.Construct (@path );
 poly1.width_    (1.5 );
 ras.add_path    (@poly1 );
 rgba.ConstrDbl  (0 ,0 ,0 );
 ren.color_      (@rgba );
 render_scanlines(@ras ,@sl ,@ren );

// (3)
 poly2_dash.Construct(@stroke );
 poly2.Construct     (@poly2_dash );
 poly2.miter_limit_  (4.0 );
 poly2.width_        (m_width._value / 5.0 );
 poly2.line_cap_     (cap );
 poly2.line_join_    (join );
 poly2_dash.add_dash (20.0 ,m_width._value / 2.5 );

 ras.add_path    (@poly2 );
 rgba.ConstrDbl  (0 ,0 ,0.3 );
 ren.color_      (@rgba );
 render_scanlines(@ras ,@sl ,@ren );

// (4)
 ras.add_path    (@path );
 rgba.ConstrDbl  (0.0 ,0.0 ,0.0 ,0.2 );
 ren.color_      (@rgba );
 render_scanlines(@ras ,@sl ,@ren );

// Render the controls
 render_ctrl(@ras ,@sl ,@ren ,@m_join );
 render_ctrl(@ras ,@sl ,@ren ,@m_cap );
 render_ctrl(@ras ,@sl ,@ren ,@m_width );
 render_ctrl(@ras ,@sl ,@ren ,@m_miter_limit );

// Free AGG resources
 ras.Destruct;
 sl.Destruct;

 path.Destruct;
 stroke.Destruct;
 poly1.Destruct;
 poly2_dash.Destruct;
 poly2.Destruct;

end;

{ ON_MOUSE_MOVE }
procedure the_application.on_mouse_move;
var
 dx ,dy : double;

begin
 if flags and mouse_left <> 0 then
  begin
   if m_idx = 3 then
    begin
     dx:=x - m_dx;
     dy:=y - m_dy;

     m_x[1 ]:=m_x[1 ] - (m_x[0 ] - dx );
     m_y[1 ]:=m_y[1 ] - (m_y[0 ] - dy );
     m_x[2 ]:=m_x[2 ] - (m_x[0 ] - dx );
     m_y[2 ]:=m_y[2 ] - (m_y[0 ] - dy );

     m_x[0 ]:=dx;
     m_y[0 ]:=dy;

     force_redraw;

     exit;

    end;

   if m_idx >= 0 then
    begin
     m_x[m_idx ]:=x - m_dx;
     m_y[m_idx ]:=y - m_dy;

     force_redraw;

    end;

  end
 else
  on_mouse_button_up(x ,y ,flags );

end;

{ ON_MOUSE_BUTTON_DOWN }
procedure the_application.on_mouse_button_down;
var
 i : unsigned;

begin
 if flags and mouse_left <> 0 then
  begin
   i:=0;

   while i < 3 do
    begin
     if Sqrt((x - m_x[i ] ) * (x - m_x[i ] ) + (y - m_y[i ] ) * (y - m_y[i ] ) ) < 20.0 then
      begin
       m_dx :=x - m_x[i ];
       m_dy :=y - m_y[i ];
       m_idx:=i;

       break;

      end;

     inc(i );

    end;

   if i = 3 then
    if point_in_triangle(
        m_x[0 ] ,m_y[0 ] ,
        m_x[1 ] ,m_y[1 ] ,
        m_x[2 ] ,m_y[2 ] ,x ,y ) then
     begin
      m_dx :=x - m_x[0 ];
      m_dy :=y - m_y[0 ];
      m_idx:=3;

     end;

  end;

end;

{ ON_MOUSE_BUTTON_UP }
procedure the_application.on_mouse_button_up;
begin
 m_idx:=-1;

end;

{ ON_KEY }
procedure the_application.on_key;
var
 dx ,dy : double;

begin
 dx:=0;
 dy:=0;

 case key of
  key_left  : dx:=-0.1;
  key_right : dx:= 0.1;
  key_up    : dy:= 0.1;
  key_down  : dy:=-0.1;

 end;

 m_x[0 ]:=m_x[0 ] + dx;
 m_y[0 ]:=m_y[0 ] + dy;
 m_x[1 ]:=m_x[1 ] + dx;
 m_y[1 ]:=m_y[1 ] + dy;

 force_redraw;

 if key = key_f1 then
  message_(
   'Another example that demonstrates the power of the custom pipeline concept. '#13 +
   'First, we calculate a thick outline (stroke), then generate dashes, and then, '#13 +
   'calculate the outlines (strokes) of the dashes again.'#13#13 +
   'How to play with:'#13#13 +
   'Use the left mouse in the corners of the triangle to move the particular vertices.'#13 +
   'Drag and move the whole picture with mouse or arrow keys.' +
   #13#13'Note: F2 key saves current "screenshot" file in this demo''s directory.  ' );

end;

VAR
 app : the_application;

BEGIN
 app.Construct(pix_format_bgr24 ,flip_y );
 app.caption_ ('AGG Example. Line Join (F1-Help)' );

 if app.init(500 ,330 ,0 ) then
  app.run;

 app.Destruct;

END.