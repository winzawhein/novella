import 'package:flutter/material.dart';

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({
    super.key,
    required this.index,
    required this.onSelected,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.auto_stories_outlined,
      Icons.bookmark_border_rounded,
      Icons.person_outline_rounded,
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(
        28,
        0,
        28,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(44),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (item) {
          final active = item == index;
          return InkResponse(
            onTap: () => onSelected(item),
            radius: 32,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                scale: active ? 1 : .9,
                child: Icon(
                  icons[item],
                  color: active ? Colors.white : const Color(0xFF9D9DA2),
                  size: 25,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
