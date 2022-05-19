# Build infrastructure with HashiCorp Configuration Language (HCL) 
HashiCorp Configuration Language (HCL) is the language used to define the Terraform configuration files. It uses a user-friendly, human readable syntax for defining the configuration for Terraform scripts. The main purpose of the Terraform language is declaring resources, which represent infrastructure objects. All other language features exist only to make the definition of resources more flexible and convenient. A Terraform configuration is a complete document in the Terraform language that tells Terraform how to manage a given collection of infrastructure. A configuration can consist of multiple files and directories. Code in the Terraform language is stored in plain text files with the `.tf` file extension. There is also a JSON-based variant of the language that is named with the `.tf.json` file extension.

## Components of Terraform Confiugration file

### Terraform block
The special `terraform` configuration block type is used to configure some behaviors of Terraform itself, such as requiring a minimum Terraform version to apply your configuration. Each terraform block can contain a number of settings related to Terraform's behavior. Within a terraform block, only constant values can be used; arguments may not refer to named objects such as resources, input variables, etc, and may not use any of the Terraform language built-in functions.
```terraform
terraform {
    required_providers {
        aws = {
            version = ">= 2.7.0"
            source = "hashicorp/aws"
        }
    }
}
```
### Comments
The Terraform language supports three different syntaxes for comments:
* `#` begins a single-line comment, ending at the end of the line.
* `//` also begins a single-line comment, as an alternative to #.
* `/* and */` are start and end delimiters for a comment that might span over multiple lines.

### Resources block
Resources are the most important element in the Terraform language. Each resource block describes one or more infrastructure objects, such as virtual networks, compute instances, or higher-level components such as DNS records. The Meta-Arguments section documents special arguments that can be used with every resource type, including `depends_on`, `count`, `for_each`, `provider`, and `lifecycle`.

A resource block declares a resource of a given type (eg:"aws_instance") with a given local name (eg:"web"). The name is used to refer to this resource from elsewhere in the same Terraform module, but has no significance outside that module's scope. Within the block body (between { and }) are the configuration arguments for the resource itself. Most arguments in this section depend on the resource type. 
```terraform
resource "aws_vpc" "my_vpc" {
    cidr_block = "172.16.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "VPC-with-Terraform"
    }
}

resource "aws_subnet" "subnet1" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "Subnet1"
    }
}

resource "aws_subnet" "subnet2" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "Subnet2"
    }
}

# Create and attach Intenet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_vpc-igw"
    }
}
```
### Providers block
Terraform relies on plugins called `providers` to interact with cloud providers, SaaS providers, and other APIs. Terraform configurations must declare which providers they require so that Terraform can install and use them. Additionally, some providers require configuration (like endpoint URLs or cloud regions) before they can be used.
Each provider adds a set of resource types and/or data sources that Terraform can manage. Every resource type is implemented by a provider; without providers, Terraform can't manage any kind of infrastructure. Providers are distributed separately from Terraform itself, and each provider has its own release cadence and version numbers.The [Terraform Registry](https://registry.terraform.io/browse/providers) is the main directory of publicly available Terraform providers, and hosts providers for most major infrastructure platforms. Provider configurations belong in the root module of a Terraform configuration. Each provider has its own documentation, describing its resource types and their arguments.

```terraform
provider "aws" {
  profile = "default"
  region  = "ap-south-1"
}
```
```terraform
provider "google" {
    project = "acme-app"
    region  = "us-central1"
}
```
### Variables and Outputs
The Terraform language includes a few kinds of blocks for requesting or publishing named values.
* **Input Variables** serve as parameters for a Terraform module, so users can customize behavior without editing the source.
* **Output Values** are like return values for a Terraform module.
* **Local Values** are a convenience feature for assigning a short name to an expression.

**Input variables** : 
When you declare variables in the root module of your configuration, you can set their values using CLI options and environment variables. When you declare them in child modules, the calling module should pass values in the module block. Input variables are like function arguments.
```terraform
variable "image_id" {
    type = string
}

variable "availability_zone_names" {
    type    = list(string)
    default = ["ap-south-1a","ap-south-1b","ap-south-1c"]
}

variable "docker_ports" {
    type = list(object({
        internal = number
        external = number
        protocol = string
    }))
    default = [
    {
        internal = 8300
        external = 8300
        protocol = "tcp"
    }]
}
```
Terraform CLI defines the following optional arguments for variable declarations:
* **default** - A default value which then makes the variable optional.
* **type** - This argument specifies what value types are accepted for the variable.
* **description** - This specifies the input variable's documentation.
* **validation** - A block to define validation rules, usually in addition to type constraints.
* **sensitive** - Limits Terraform UI output when the variable is used in configuration.
* **nullable** - Specify if the variable can be null within the module.

The `type` argument in a variable block allows you to restrict the type of value that will be accepted as the value for a variable. If no type constraint is set then a value of `any` type is accepted. While `type` constraints are optional, it is recommended to specify them; they can serve as helpful reminders for users of the module, and they allow Terraform to return a helpful error message if the wrong type is used.
Type constraints are created from a mixture of type keywords and type constructors. The supported type keywords are:
* **string**
* **number**
* **bool**

The type constructors allow you to specify complex types such as collections:
* **list(<TYPE>)**
* **set(<TYPE>)**
* **map(<TYPE>)**
* **object({<ATTR NAME> = <TYPE>, ... })**
* **tuple([<TYPE>, ...])**

The keyword `any` may be used to indicate that any type is acceptable. 

In addition to Type Constraints as described above, a module author can specify arbitrary custom validation rules for a particular variable using a validation block nested within the corresponding variable block:
```terraform
variable "image_id" {
    type        = string
    description = "The id of the machine image (AMI) to use for the server."

    validation {
        condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
        error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
    }
}
```

Setting a variable as `sensitive` prevents Terraform from showing its value in the plan or apply output, when you use that variable elsewhere in your configuration.
```terraform
variable "user_information" {
    type = object({
        name    = string
        address = string
    })
    sensitive = true
}

resource "some_resource" "a" {
    name    = var.user_information.name
    address = var.user_information.address
}
```
The `nullable` argument in a variable block controls whether the module caller may assign the value null to the variable.
```terraform
variable "example" {
    type     = string
    nullable = false 
}
```
Within the module that declared a variable, its value can be accessed from within expressions as `var.<NAME>`, where `<NAME>` matches the label given in the declaration block:
```terraform
variable "image_id" {
    type        = string
    description = "The id of the machine image (AMI) to use for the server."

    validation {
        condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
        error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
    }
}
resource "aws_instance" "example" {
    instance_type = "t2.micro"
    ami           = var.image_id
}
```
**Output Values**: Output values make information about your infrastructure available on the command line, and can expose information for other Terraform configurations to use. Output values are similar to return values in programming languages. 

Each output value exported by a module must be declared using an output block:
```terraform
output "instance_ip_addr" {
    value = aws_instance.server.private_ip
}
```
The label immediately after the output keyword is the name, which must be a valid identifier. In a root module, this name is displayed to the user; in a child module, it can be used to access the output's value.

**Local Values** : A local value assigns a name to an expression, so you can use it multiple times within a module without repeating it. 

A set of related local values can be declared together in a single locals block:
```terraform
locals {
    service_name = "forum"
    owner        = "Community Team"
}
```
The expressions in local values are not limited to literal constants; they can also reference other values in the module in order to transform or combine them, including variables, resource attributes, or other local values:
```terraform
locals {
    # Ids for multiple sets of EC2 instances, merged together
    instance_ids = concat(aws_instance.blue.*.id, aws_instance.green.*.id)
}
locals {
    # Common tags to be assigned to all resources
    common_tags = {
        Service = local.service_name
        Owner   = local.owner
    }
}
```
Once a local value is declared, you can reference it in expressions as `local.<NAME>`.
```terraform
resource "aws_instance" "example" {
    ....
    tags = local.common_tags
}
```
## Modules
A module is a container for multiple resources that are used together. Every Terraform configuration has at least one module, known as its *root module*, which consists of the resources defined in the `.tf` files in the main working directory. A module can call other modules, which lets you include the child module's resources into the configuration in a concise way. Modules can also be called multiple times, either within the same configuration or in separate configurations, allowing resource configurations to be packaged and re-used.

Modules are containers for multiple resources that are used together. A module consists of a collection of `.tf` and/or `.tf.json` files kept together in a directory. Modules are the main way to package and reuse resource configurations with Terraform.

### Root Module
Every Terraform configuration has at least one module, known as its root module, which consists of the resources defined in the .tf files in the main working directory.
### Child Modules
A Terraform module (usually the root module of a configuration) can call other modules to include their resources into the configuration. A module that has been called by another module is often referred to as a child module. Child modules can be called multiple times within the same configuration, and multiple configurations can use the same child module.
### Published Modules
In addition to modules from the local filesystem, Terraform can load modules from a public or private registry. This makes it possible to publish modules for others to use, and to use modules that others have published. The Terraform Registry hosts a broad collection of publicly available Terraform modules for configuring many kinds of common infrastructure. These modules are free to use, and Terraform can download them automatically if you specify the appropriate source and version in a module call block.

### Calling child modules
To call a module means to include the contents of that module into the configuration with specific values for its input variables. Modules are called from within other modules using module blocks:
```terraform
module "servers" {
    source = "./app-cluster"
    servers = 5
}
```
The label immediately after the module keyword is a local name, which the calling module can use to refer to this instance of the module. Within the block body (between `{` and `}`) are the arguments for the module. Module calls use the following kinds of arguments:
* The **source** argument is mandatory for all modules. The `source` argument in a module block tells Terraform where to find the source code for the desired child module. Terraform uses this during the module installation step of terraform init to download the source code to a directory on local disk so that it can be used by other Terraform commands. The module installer supports installation from a number of different source types, as listed below.
    * Local paths
    * Terraform Registry
    * GitHub
    * Bitbucket
    * Generic Git, Mercurial repositories
    * HTTP URLs
    * S3 buckets
    * GCS buckets
    * Modules in Package Sub-directories
* The **version** argument is recommended for modules from a registry. When using modules installed from a module registry, we recommend explicitly constraining the acceptable version numbers to avoid unexpected or unwanted changes.
    ```terraform
    module "consul" {
        source  = "hashicorp/consul/aws"
        version = "0.0.5"
    
        servers = 3
    }
    ```
* Most other arguments correspond to input variables defined by the module. 
* Terraform defines a few other meta-arguments that can be used with all modules, including `for_each` and `depends_on`.

### Accessing Module Output Values
The resources defined in a module are encapsulated, so the calling module cannot access their attributes directly. However, the child module can declare `output` values to selectively export certain values to be accessed by the calling module.
```terraform
resource "aws_elb" "example" {
    # ...
    
    instances = module.servers.instance_ids
}
```
## Expressions
Expressions are used to refer to or compute values within a configuration. Expressions can be used in a number of places in the Terraform language, but some contexts limit which expression constructs are allowed, such as requiring a literal value of a particular type or forbidding references to resource attributes.
### Types and Values
The result of an expression is a value. All values have a type, which dictates where that value can be used and what transformations can be applied to it. The Terraform language uses the following types for its values:
* **string**: a sequence of Unicode characters representing some text, like "hello".
* **number**: a numeric value. The number type can represent both whole numbers like 15 and fractional values like 6.283185.
* **bool**: a boolean value, either true or false. bool values can be used in conditional logic.
* **list (or tuple)**: a sequence of values, like ["us-west-1a", "us-west-1c"]. Elements in a list or tuple are identified by consecutive whole numbers, starting with zero.
* **map (or object)**: a group of values identified by named labels, like {name = "Mabel", age = 52}.

### Strings and Templates
String literals are the most complex kind of literal expression in Terraform, and also the most commonly used. Terraform supports both a quoted syntax and a "heredoc" syntax for strings. Both of these syntaxes support template sequences for interpolating values and manipulating text.
* **Quoted Strings**: A quoted string is a series of characters delimited by straight double-quote characters (").
    ```terraform
    "hello"
    ```
* **Heredoc Strings**: Terraform also supports a "heredoc" style of string literal inspired by Unix shell languages, which allows multi-line strings to be expressed more clearly.
    ```terraform
    <<EOT
    hello
    world
    EOT
    ```
* **Generating JSON or YAML** : Don't use "heredoc" strings to generate JSON or YAML. Instead, use the `jsonencode` function or the `yamlencode` function so that Terraform can be responsible for guaranteeing valid JSON or YAML syntax.
    ```terraform
    example = jsonencode({
        a = 1
        b = "hello"
    })
    ```

* **String Templates**: Within quoted and heredoc string expressions, the sequences `${` and `%{` begin template sequences. Templates let you directly embed expressions into a string literal, to dynamically construct strings from other values.
    * **Interpolation** <br/>
    A ${ ... } sequence is an interpolation, which evaluates the expression given between the markers, converts the result to a string if necessary, and then inserts it into the final string:
        ```terraform
        "Hello, ${var.name}!"
        ```
    * **Directives**<br/>
    A %{ ... } sequence is a directive, which allows for conditional results and iteration over collections, similar to conditional and for expressions.
    The `%{if <BOOL>}/%{else}/%{endif}` directive chooses between two templates based on the value of a bool expression:
        ```terraform
        "Hello, %{ if var.name != "" }${var.name}%{ else }unnamed%{ endif }!"
        ```
        The `%{for <NAME> in <COLLECTION>} / %{endfor}` directive iterates over the elements of a given collection or structural value and evaluates a given template once for each element, concatenating the results together:
        ```terraform
        <<EOT
        %{ for ip in aws_instance.example.*.private_ip }
        server ${ip}
        %{ endfor }
        EOT
        ```
### References to Named Values
Terraform makes several kinds of named values available. Each of these names is an expression that references the associated value; you can use them as standalone expressions, or combine them with other expressions to compute new values.
The main kinds of named values available in Terraform are:
* **Resources**<br/>
`<RESOURCE TYPE>.<NAME>` represents a managed resource of the given type and name. The value of a resource reference can vary, depending on whether the resource uses count or for_each:
    * If the resource doesn't use `count` or `for_each`, the reference's value is an object. The resource's attributes are elements of the object, and you can access them using dot or square bracket notation.
    * If the resource has the `count` argument set, the reference's value is a list of objects representing its instances.
    * If the resource has the `for_each` argument set, the reference's value is a map of objects representing its instances.
    ```terraform
    resource "aws_instance" "example" {
        ami           = "ami-abc123"
        instance_type = "t2.micro"
    }
    ```
    The `ami` argument set in the configuration can be used elsewhere with the reference expression `aws_instance.example.ami`. The `id` attribute exported by this resource type can be read using the same syntax, giving `aws_instance.example.id`.
* **Input variables** <br/>
`var.<NAME>` is the value of the input variable of the given name. If the variable has a type constraint (type argument) as part of its declaration, Terraform will automatically convert the caller's given value to conform to the type constraint.
    ```terraform
    variable "example" {
      type     = string
      nullable = false 
    }
    resource "aws_instance" "example" {
      instance_type = "t2.micro"
      ami           = var.image_id
    }
    ```
* **Local values**<br/>
`local.<NAME>` is the value of the local value of the given name. Local values can refer to other local values, even within the same locals block, as long as you don't introduce circular dependencies.
    ```terraform
    locals {
        service_name = "forum"
        owner        = "Community Team"
    }
    locals {
        # Common tags to be assigned to all resources
        common_tags = {
            Service = local.service_name
            Owner   = local.owner
        }
    }
    resource "aws_instance" "example" {
        # ...
    
        tags = local.common_tags
    }
    ```
* **Child module outputs**
`module.<MODULE NAME>` is an value representing the results of a module block. To access one of the module's output values, use `module.<MODULE NAME>.<OUTPUT NAME>`.
    ```terraform
    module "foo" {
      source = "./mod"
    }
    resource "test_instance" "x" {
      some_attribute = module.mod.a # resource attribute references a sensitive output
    }
    output "a" {
      value     = "secret"
      sensitive = true
    }
    ```
* **Data sources**<br/>
`data.<DATA TYPE>.<NAME>` is an object representing a data resource of the given data source type and name. Data sources allow Terraform to use information defined outside of Terraform, defined by another separate Terraform configuration, or modified by functions.
    ```terraform
    data "aws_ami" "example" {
        most_recent = true

        owners = ["self"]
        tags = {
            Name   = "app-server"
            Tested = "true"
        }
    }
    ```
    ```terraform
    resource "aws_instance" "web" {
        ami           = "${data.aws_ami.example.id}"
        instance_type = "t2.micro"
    }
    ```
* **Filesystem and workspace info**<br/>
    * `path.module` is the filesystem path of the module where the expression is placed.
    * `path.root` is the filesystem path of the root module of the configuration.
    * `path.cwd` is the filesystem path of the current working directory. In normal use of Terraform this is the same as `path.root`, but some advanced uses of Terraform run it from a directory other than the root module directory, causing these paths to be different.
    * `terraform.workspace` is the name of the currently selected workspace.
        ```terraform
        module "example" {
            # ...
        
            name_prefix = "app-${terraform.workspace}"
        }
        ```
* **Block-local values**
Some of most common local names are:
    * `count.index`, in resources that use the count meta-argument.
        ```terraform
        resource "aws_instance" "server" {
          count = 4 # create four similar EC2 instances
        
          ami           = "ami-a1b2c3d4"
          instance_type = "t2.micro"
        
          tags = {
            Name = "Server ${count.index}"
          }
        }
        ```
    * `each.key / each.value`, in resources that use the `for_each` meta-argument.
        ```terraform
        resource "aws_iam_user" "the-accounts" {
          for_each = toset( ["Todd", "James", "Alice", "Dottie"] )
          name     = each.key
        }
        ```
    * `self`, in provisioner and connection blocks.
        ```terraform
        resource "aws_instance" "web" {
            # ...
            provisioner "local-exec" {
                command = "echo The server's IP address is ${self.private_ip}"
              }
        }
        ```

### Conditional Expressions
A conditional expression uses the value of a boolean expression to select one of two values. The syntax of a conditional expression is as follows:
```terraform
condition ? true_val : false_val
```
If condition is `true` then the result is `true_val`. If condition is `false` then the result is `false_val`. A common use of conditional expressions is to define defaults to replace invalid values:
```terraform
var.a != "" ? var.a : "default-a"
```

### for Expressions
A `for` expression creates a complex type value by transforming another complex type value. Each element in the input value can correspond to either one or zero values in the result, and an arbitrary expression can be used to transform each input element into an output element.

For example, if var.list were a list of strings, then the following expression would produce a tuple of strings with all-uppercase letters:
```terraform
[for s in var.list : upper(s)]
```

A `for` expression's input (given after the in keyword) can be a `list`, a `set`, a `tuple`, a `map`, or an `object`.
```terraform
[for k, v in var.map : length(k) + length(v)]

[for i, v in var.list : "${i} is ${v}"]
```

The above example uses `[ and ]`, which produces a `tuple`. If you use `{ and }` instead, the result is an `object` and you must provide two result expressions that are separated by the `=>` symbol:
```terraform
{for s in var.list : s => upper(s)}
```
The the resulting value might be as follows:
```terraform
{
  foo = "FOO"
  bar = "BAR"
  baz = "BAZ"
}
```

## Functions
The Terraform language includes a number of built-in functions that you can call from within expressions to transform and combine values. The general syntax for function calls is a function name followed by comma-separated arguments in parentheses:
```terraform
max(5, 12, 9)
```

The built-in functions in HCL comes under the following categories:
* **Numeric Functions** : abs, ceil, floor, log, max, min, orseint, pow, signum
* **String Functions** : indent, lower, upper, regex, replace, split, strrev, substr, trim etc
* **Collection functions** : alltrue, anytrue, concat, compact, distinct, element, index, length, list, map, merge, range, reverce etc
* **Encoding functions**: jsonencode, jsondecode, yamldecode, yamlencode, urlencode, textencodebase64, textdecodebase64, csvdecode etc
* **Filesystem functions** : abspath, dirname, pathexpand, file, basename, fileexists etc
* **Date and Time functions**: timeaddm timestamp, formatdate
* **IP Network functions** : cidrhost, cidrnetmask, cidrsubnet, cidrsubnets
* **Type conversion functions**: can ,defaults, nonsensitive, sensitive, tobool, tolist, tomap, toset, tonumber, tostring, try, type




