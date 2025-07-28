
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/circular_container.dart';

class TChoiceChip extends StatelessWidget {
  const TChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    this.onSelected,
    this.isOutOfStock = false,
  });
  final String text;
  final bool selected;
  final void Function(bool)? onSelected;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: ChoiceChip(
        label: THelperFunctions.getColor(text) != null
            ? const SizedBox()
            : Text(
                text,
                style: TextStyle(
                  color: isOutOfStock
                      ? TColors.glowPurple
                      : (selected ? TColors.white : null),
                  decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                ),
              ),
        selected: selected && !isOutOfStock,
        onSelected: isOutOfStock ? null : onSelected,
        labelStyle: TextStyle(
          color:
              isOutOfStock ? TColors.glowPurple : (selected ? TColors.white : null),
          decoration: isOutOfStock ? TextDecoration.lineThrough : null,
        ),
        avatar: THelperFunctions.getColor(text) != null
            ? TCircularContainer(
                width: 50,
                height: 50,
                backgroundColor: isOutOfStock
                    ? TColors.glowPurple.withValues(alpha : 0.5)
                    : THelperFunctions.getColor(text)!,
                child: isOutOfStock
                    ? const Icon(
                        Icons.close,
                        color: TColors.white,
                        size: 20,
                      )
                    : null,
              )
            : isOutOfStock
                ? const Icon(
                    Icons.close,
                    color: TColors.glowPurple,
                    size: 16,
                  )
                : null,
        shape: THelperFunctions.getColor(text) != null ? const CircleBorder() : null,
        backgroundColor: isOutOfStock
            ? TColors.glowPurple.withValues(alpha : 0.3)
            : (THelperFunctions.getColor(text)),
        labelPadding: THelperFunctions.getColor(text) != null
            ? const EdgeInsets.all(0)
            : null,
        padding:
            THelperFunctions.getColor(text) != null ? const EdgeInsets.all(0) : null,
        selectedColor: isOutOfStock
            ? TColors.glowPurple.withValues(alpha : 0.3)
            : (THelperFunctions.getColor(text)),
        disabledColor: TColors.glowPurple.withValues(alpha : 0.3),
      ),
    );
  }
}
