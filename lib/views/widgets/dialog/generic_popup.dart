import 'package:driver_app/helper/colors.dart';
import 'package:driver_app/views/widgets/button/Default_Button.dart';
import 'package:driver_app/views/widgets/label/default_label.dart';
import 'package:driver_app/views/widgets/textfeild/Default_textfeild.dart';
import 'package:flutter/material.dart';

class GenericSelectionItemPopup extends StatefulWidget {
  final String message;
  final List<String> reasons; // Accept a list of reasons
  final String defaultTextFiledHint;

  GenericSelectionItemPopup(
      {required this.message,
      required this.reasons, // Pass the list of reasons
      required this.defaultTextFiledHint});

  @override
  _GenericSelectionItemPopupState createState() =>
      _GenericSelectionItemPopupState();
}

class _GenericSelectionItemPopupState extends State<GenericSelectionItemPopup> {
  String? selectedChoice;
  TextEditingController textEditingController = TextEditingController();
  bool addingNewChoice = false;

  void addChoice(String choice) {
    setState(() {
      widget.reasons.add(choice); // Add new choice to the list
      selectedChoice = choice;
      addingNewChoice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: DefaultLabel(
        text: widget.message,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          reasonSelectionView(), // Call the generic method
          if (addingNewChoice)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: SizedBox(
                      height: 60,
                      child: DefaultTextField(
                        maxChar: 25,
                        textEditingController: textEditingController,
                        hint: widget.defaultTextFiledHint,
                        isPrimary: false,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3),
                SizedBox(
                  width: 50,
                  height: 45,
                  child: DefaultButton(
                    name: "Done",
                    onPressed: () {
                      addChoice(textEditingController.text);
                      textEditingController.clear();
                    },
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }

  Widget reasonSelectionView() {
    return Wrap(
      children: List.generate(widget.reasons.length, (choiceIndex) {
        final choice = widget.reasons[choiceIndex];
        final isSelected = selectedChoice == choice;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                label: DefaultLabel(
                  text: choice,
                  fontSize: 12,
                ),
                selected: isSelected,
                selectedColor: ColorSys.kPrimary,
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedChoice = choice;
                      Navigator.pop(context, selectedChoice);
                    } else {
                      selectedChoice = null;
                    }
                  });
                },
              ),
              if (choiceIndex ==
                  widget.reasons.length -
                      1) // Show '+' icon for the last choice
                InkWell(
                  onTap: () {
                    setState(() {
                      addingNewChoice = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.add,
                      color: ColorSys.kPrimary,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
