def deprecated_attribute(
        ctx,
        old_attribute_name,
        new_attribute_name = None,
        action = None):
    if getattr(ctx.attr, old_attribute_name) != None:
        if action != None:
            print("Attribute \"%s\" is deprecated — \"%s\"" % (old_attribute_name, action))
        elif new_attribute_name != None:
            print("Attribute \"%s\" is deprecated in favor of \"%s\"" % (old_attribute_name, new_attribute_name))
        else:
            print("Attribute \"%s\" is deprecated. Please do not use it." % (old_attribute_name))
