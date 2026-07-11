import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/config/router/routes.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_drawer.dart';

/// 모든 페이지에서 사용해야 하는 공통 Scaffold Widget
///
/// **용도**: Drawer와 Bottom Navigation Bar를 일관되게 관리
/// - Drawer는 항상 Bottom Nav를 덮지 않음
/// - 모든 페이지에서 동일한 네비게이션 경험 제공
/// - 페이지별로 반복되는 Stack/Positioned 코드 제거
///
/// **필수 사용 규칙**:
/// 1. 새로운 페이지 생성 시 항상 ScaffoldWithNavBar 사용
/// 2. 커스텀 drawer가 필요한 경우도 이 widget을 상속/확장하여 구현
/// 3. Stack이나 Positioned로 bottom nav를 직접 구현하면 안됨 (⚠️ 코드 중복 및 유지보수 문제)
///
/// **사용 예제**:
/// ```dart
/// // 1. 일반 페이지 (목록, 검색)
/// ScaffoldWithNavBar(
///   title: '상품 조회',
///   navBarIndex: 2,
///   body: ListView(...),
/// )
///
/// // 2. Detail 페이지 (뒤로가기 버튼 필요)
/// ScaffoldWithNavBar(
///   title: '상품 상세',
///   navBarIndex: 2,
///   onBackPressed: () => context.go(Routes.productSearchPath),
///   body: SingleChildScrollView(...),
/// )
///
/// // 3. Drawer를 숨겨야 하는 페이지
/// ScaffoldWithNavBar(
///   title: '설정',
///   navBarIndex: 3,
///   showDrawer: false,
///   body: SettingsView(),
/// )
/// ```
///
/// **Parameters**:
/// - `title`: AppBar에 표시될 페이지 제목
/// - `body`: 페이지의 주요 콘텐츠 (required)
/// - `navBarIndex`: 현재 선택된 bottom nav 인덱스 (0=menu, 1=home, 2=list, 3=notification)
/// - `showDrawer`: Drawer 표시 여부 (기본값: true)
/// - `onBackPressed`: 뒤로가기 버튼 클릭 시 동작 (null이면 back button 표시 안함)
///
/// ⚠️ **주의**: 다른 방식으로 drawer/bottom nav를 구현하지 마세요
/// - ❌ Stack + Positioned로 직접 구현
/// - ❌ 각 페이지마다 다른 구조로 구현
/// - ❌ Scaffold에 bottomNavigationBar를 직접 설정
///
class ScaffoldWithNavBar extends StatefulWidget {
  final String title;
  final Widget body;
  final int navBarIndex;
  final bool showDrawer;
  final bool showAppBarDrawerButton;
  final VoidCallback? onBackPressed;

  /// Body background color. Defaults to null → falls back to grey[100].
  /// Pass `Colors.white` for pages that need a plain white background.
  final Color? backgroundColor;

  const ScaffoldWithNavBar({
    required this.title,
    required this.body,
    required this.navBarIndex,
    this.showDrawer = true,
    this.showAppBarDrawerButton = true,
    this.onBackPressed,
    this.backgroundColor,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  late final GlobalKey<ScaffoldState> _scaffoldKey;
  bool _previousDrawerState = false;

  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    if (widget.showDrawer) {
      WidgetsBinding.instance.addPersistentFrameCallback((_) {
        final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
        if (isOpen != _previousDrawerState) {
          _previousDrawerState = isOpen;
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawerScrimColor: Colors.black.withOpacity(0.3),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.onBackPressed != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: widget.onBackPressed,
                  )
                : (widget.showDrawer && widget.showAppBarDrawerButton
                    ? IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      )
                    : null),
            title: Text(widget.title),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: widget.backgroundColor ?? Colors.grey[100],
          body: widget.body,
          bottomNavigationBar: SizedBox.shrink(),
          drawer: widget.showDrawer ? const AppDrawer() : null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) {
              final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;

              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: widget.navBarIndex,
                selectedItemColor: AppColors.brandMain,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.menu,
                      color: isDrawerOpen ? AppColors.brandMain : Colors.black87,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.checklist),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.notifications),
                    label: '',
                  ),
                ],
                onTap: (index) {
                  switch (index) {
                    case 0:
                      if (widget.showDrawer) {
                        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                          Navigator.pop(context);
                        } else {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                        setState(() {});
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      }
                      break;
                    case 1:
                      context.go(Routes.dashboardPath);
                      break;
                    case 2:
                      context.go(Routes.listToShopPath);
                      break;
                    case 3:
                      context.go(Routes.notificationPath);
                      break;
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
